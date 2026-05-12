#!/usr/bin/env python3
# Temperature Bridge v12.0 — Multi-sensor MQTT → D-Bus (single process)

import configparser
import json
import logging
import os
import signal
import sys
import traceback
from typing import Dict, Any

from gi.repository import GLib
import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion

# Libreria ufficiale Victron
sys.path.insert(1, os.path.join(
    os.path.dirname(__file__),
    '/opt/victronenergy/dbus-systemcalc-py/ext/velib_python'
))
from vedbus import VeDbusService
from dbus.mainloop.glib import DBusGMainLoop

DBusGMainLoop(set_as_default=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# --- Config ---
MQTT_RETRY_SECONDS = 5
# --- End Config ---


class DbusSensorService:
    """Rappresenta un singolo sensore esposto su D-Bus."""

    def __init__(self, sensor_id: str, custom_name: str,
                 device_instance: int, publish_flags: Dict[str, bool]):
        service_name = f"com.victronenergy.temperature.mqtt_{sensor_id}"
        self._publish_flags = publish_flags
        self._sensor_id = sensor_id

        self._svc = VeDbusService(service_name, register=False)
        logging.info(
            f"Preparing D-Bus service {service_name} "
            f"instance {device_instance}"
        )

        self._svc.add_path('/Mgmt/ProcessName', __file__)
        self._svc.add_path('/Mgmt/ProcessVersion', '12.0')
        self._svc.add_path('/DeviceInstance', device_instance)
        self._svc.add_path('/ProductId', 0)
        self._svc.add_path('/ProductName', f"MQTT Sensor: {custom_name}")
        self._svc.add_path('/Connected', 1)
        self._svc.add_path('/Status', 0)
        self._svc.add_path('/CustomName', custom_name)

        # Path opzionali: aggiunti solo se abilitati nel config
        self._paths = {}
        if publish_flags.get('temperature', True):
            self._svc.add_path('/Temperature', None)
            self._paths['temperature'] = '/Temperature'
        if publish_flags.get('humidity', True):
            self._svc.add_path('/Humidity', None)
            self._paths['humidity'] = '/Humidity'
        if publish_flags.get('pressure', True):
            self._svc.add_path('/Pressure', None)
            self._paths['pressure'] = '/Pressure'

        self._svc.register()
        logging.info(
            f"D-Bus service registered: {custom_name} "
            f"(temperature={'yes' if 'temperature' in self._paths else 'no'}, "
            f"humidity={'yes' if 'humidity' in self._paths else 'no'}, "
            f"pressure={'yes' if 'pressure' in self._paths else 'no'})"
        )

    def update(self, data: Dict[str, Any]):
        """Aggiorna i valori D-Bus a partire dai dati del sensore."""
        for key, dbus_path in self._paths.items():
            if key in data and data[key] is not None:
                try:
                    self._svc[dbus_path] = float(data[key])
                except (ValueError, TypeError) as e:
                    logging.error(
                        f"[{self._sensor_id}] Invalid {key} value: "
                        f"{data[key]} — {e}"
                    )


class TemperatureBridge:
    """Bridge MQTT → D-Bus per array JSON di sensori temperatura."""

    def __init__(self, config_path: str):
        self._config = configparser.ConfigParser()
        self._config.read(config_path)
        self._cfg = self._config['DEFAULT']

        self._mqtt_connected = False
        self._socket_watch = None
        self._socket_timer = None
        self._shutdown = False
        self._mainloop = None

        # Crea servizi D-Bus per ogni sensore
        self._sensors: Dict[str, DbusSensorService] = {}
        self._init_sensors()

        # Setup MQTT
        self._setup_mqtt()

    def _init_sensors(self):
        """Crea un DbusSensorService per ogni sezione del config."""
        for section in self._config.sections():
            custom_name = self._config.get(section, 'CustomName')
            device_instance = self._config.getint(section, 'DeviceInstance')

            publish_flags = {
                'temperature': self._config.getboolean(
                    section, 'PublishTemperature', fallback=True
                ),
                'humidity': self._config.getboolean(
                    section, 'PublishHumidity', fallback=True
                ),
                'pressure': self._config.getboolean(
                    section, 'PublishPressure', fallback=True
                ),
            }

            sensor = DbusSensorService(
                sensor_id=section,
                custom_name=custom_name,
                device_instance=device_instance,
                publish_flags=publish_flags,
            )
            self._sensors[section] = sensor

        logging.info(
            f"Initialized {len(self._sensors)} D-Bus sensor services."
        )

    # ================================================================
    # MQTT — integrato in GLib main loop
    # ================================================================

    def _setup_mqtt(self):
        broker = self._cfg.get('MqttBroker', '127.0.0.1')
        port = self._cfg.getint('MqttPort', 1883)
        topic = self._cfg.get('MqttTopic', 'venusOS/temperature/sensors')
        self._mqtt_topic = topic

        self._client = mqtt.Client(
            CallbackAPIVersion.VERSION1,
            client_id=f"TempBridge-{os.getpid()}"
        )
        self._client.on_connect = self._on_connect
        self._client.on_message = self._on_message
        self._client.on_disconnect = self._on_disconnect

        # LWT
        self._client.will_set(
            f"{topic}/bridge/online", "0", retain=True
        )

        # Credenziali opzionali
        mqtt_user = self._cfg.get('MqttUser', '')
        mqtt_pass = self._cfg.get('MqttPass', '')
        if mqtt_user:
            self._client.username_pw_set(mqtt_user, mqtt_pass)

        self._mqtt_broker = broker
        self._mqtt_port = port
        self._init_mqtt()

    def _init_mqtt(self):
        """Tentativo connessione MQTT. Retry se fallisce."""
        try:
            logging.info(
                f"Connecting to MQTT broker {self._mqtt_broker}:{self._mqtt_port}..."
            )
            self._client.connect(self._mqtt_broker, self._mqtt_port, 60)
            self._setup_socket_handlers()
            return False
        except Exception as e:
            logging.error(f"MQTT connection failed: {e}, retrying in {MQTT_RETRY_SECONDS}s")
            GLib.timeout_add_seconds(MQTT_RETRY_SECONDS, self._init_mqtt)
            return False

    def _setup_socket_handlers(self):
        if self._socket_watch is not None:
            GLib.source_remove(self._socket_watch)
            self._socket_watch = None
        try:
            sock = self._client.socket()
            self._socket_watch = GLib.io_add_watch(
                sock.fileno(), GLib.IO_IN, self._on_socket_in
            )
        except Exception as e:
            logging.warning(f"Cannot setup MQTT socket watch: {e}")
            return
        if self._socket_timer is None:
            self._socket_timer = GLib.timeout_add_seconds(
                1, self._on_socket_timer
            )
        logging.info("MQTT socket handlers installed in GLib main loop.")

    def _on_socket_in(self, source, condition):
        try:
            self._client.loop_read()
        except Exception:
            logging.error("MQTT loop_read error:\n" + traceback.format_exc())
        return True

    def _on_socket_timer(self):
        try:
            self._client.loop_misc()
            while self._client.want_write():
                rc = self._client.loop_write(10)
                if rc != mqtt.MQTT_ERR_SUCCESS:
                    break
        except Exception:
            logging.error("MQTT timer error:\n" + traceback.format_exc())
        return True

    # --- Callback MQTT ---

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            self._mqtt_connected = True
            logging.info(
                f"Connected to MQTT, subscribing to {self._mqtt_topic}"
            )
            self._client.subscribe(self._mqtt_topic)
            self._client.publish(
                f"{self._mqtt_topic}/bridge/online", "1", retain=True
            )
            # Alla riconnessione, publish flag Connected su tutti i sensori
            for sid, sensor in self._sensors.items():
                try:
                    sensor._svc['/Connected'] = 1
                except Exception:
                    pass
        else:
            logging.error(f"MQTT connection failed with code: {rc}")

    def _on_disconnect(self, client, userdata, rc):
        self._mqtt_connected = False
        logging.warning(f"Disconnected from MQTT. Code: {rc}")

        # Pubblica offline sui sensori D-Bus
        for sid, sensor in self._sensors.items():
            try:
                sensor._svc['/Connected'] = 0
            except Exception:
                pass

        try:
            self._client.publish(
                f"{self._mqtt_topic}/bridge/online", "0", retain=True
            )
        except Exception:
            pass

        # Rimuovi socket watch
        if self._socket_watch is not None:
            GLib.source_remove(self._socket_watch)
            self._socket_watch = None

        # Schedule riconnessione
        if not self._shutdown:
            logging.info(f"Reconnecting in {MQTT_RETRY_SECONDS}s...")
            GLib.timeout_add_seconds(MQTT_RETRY_SECONDS, self._reconnect_mqtt)

    def _reconnect_mqtt(self):
        if self._shutdown:
            return False
        try:
            logging.info("Attempting MQTT reconnect...")
            self._client.reconnect()
            self._setup_socket_handlers()
            logging.info("MQTT reconnect successful.")
            return False
        except Exception as e:
            logging.error(f"MQTT reconnect failed: {e}")
            return True

    def _on_message(self, client, userdata, msg):
        try:
            payload = json.loads(msg.payload)
        except json.JSONDecodeError as e:
            logging.error(f"Invalid JSON payload: {e}")
            return

        json_root = self._cfg.get('JsonArrayRoot', 'sensors')
        sensor_id_key = self._cfg.get('SensorIdKey', 'id')
        sensor_array = payload.get(json_root, [])

        if not isinstance(sensor_array, list):
            logging.warning(
                f"Expected array under '{json_root}', got {type(sensor_array).__name__}"
            )
            return

        for sensor_data in sensor_array:
            sid = sensor_data.get(sensor_id_key)
            if sid and sid in self._sensors:
                self._sensors[sid].update(sensor_data)

    # ================================================================
    # GRACEFUL SHUTDOWN
    # ================================================================

    def _handle_sigterm(self, signum, frame):
        sig_name = signal.Signals(signum).name
        logging.info(f"Received {sig_name}, initiating graceful shutdown...")
        self._shutdown = True

        if self._mqtt_connected:
            try:
                self._client.publish(
                    f"{self._mqtt_topic}/bridge/online", "0", retain=True
                )
                self._client.loop_misc()
                while self._client.want_write():
                    self._client.loop_write(100)
            except Exception:
                pass

        # Segnala sensori offline su D-Bus
        for sid, sensor in self._sensors.items():
            try:
                sensor._svc['/Connected'] = 0
            except Exception:
                pass

        try:
            self._client.disconnect()
        except Exception:
            pass

        if self._socket_watch is not None:
            GLib.source_remove(self._socket_watch)
        if self._socket_timer is not None:
            GLib.source_remove(self._socket_timer)

        if self._mainloop is not None:
            self._mainloop.quit()

        logging.info("Shutdown complete.")


# ================================================================
# MAIN
# ================================================================

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, 'config.ini')

    if not os.path.exists(config_path):
        logging.error(f"Config file not found: {config_path}")
        sys.exit(1)

    bridge = TemperatureBridge(config_path)

    signal.signal(signal.SIGTERM, bridge._handle_sigterm)
    signal.signal(signal.SIGINT, bridge._handle_sigterm)

    logging.info("Starting main loop.")
    bridge._mainloop = GLib.MainLoop()
    bridge._mainloop.run()
