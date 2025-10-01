#!/usr/-bin/env python3
# Worker Script v11.4 - Correct Victron library path

import configparser
import json
import logging
import os
import sys
from typing import Dict, Any

try:
    # Attempt to import required libraries
    import paho.mqtt.client as mqtt
    from gi.repository import GLib
except ImportError:
    # If they are missing, exit with a helpful message
    print("ERROR: Missing required Python libraries.")
    print("Please run: opkg update && opkg install python3-pip")
    print("And then:   pip install paho-mqtt pygobject")
    sys.exit(1)

sys.path.insert(1, os.path.join(os.path.dirname(__file__), '/opt/victronenergy/dbus-systemcalc-py/ext/velib_python'))
from vedbus import VeDbusService

# --- Logging Setup ---
log_format = f'%(asctime)s - %(levelname)s - [{sys.argv[1] if len(sys.argv) > 1 else "---"}] %(message)s'
logging.basicConfig(level=logging.INFO, format=log_format)

class DbusSingleSensorService:
    def __init__(self, sensor_id: str, custom_name: str, device_instance: int):
        service_name = f"com.victronenergy.temperature.mqtt_{sensor_id}"
        
        self._dbusservice = VeDbusService(service_name, register=False)
        logging.info(f"Preparing D-Bus service {service_name} with instance {device_instance}")

        self._dbusservice.add_path('/Mgmt/ProcessName', __file__)
        self._dbusservice.add_path('/Mgmt/ProcessVersion', '11.4-final')
        self._dbusservice.add_path('/DeviceInstance', device_instance)
        self._dbusservice.add_path('/ProductId', 0)
        self._dbusservice.add_path('/ProductName', f"MQTT Sensor: {custom_name}")
        self._dbusservice.add_path('/Connected', 1)
        self._dbusservice.add_path('/Status', 0)
        self._dbusservice.add_path('/CustomName', custom_name)
        self._dbusservice.add_path('/Temperature', None)
        self._dbusservice.add_path('/Humidity', None)
        self._dbusservice.add_path('/Pressure', None)

        self._dbusservice.register()
        logging.info("D-Bus service successfully registered.")

    def update_values(self, data: Dict[str, Any]):
        logging.info(f"Updating values for {self._dbusservice['/CustomName']}")
        try:
            if 'temperature' in data and data['temperature'] is not None:
                self._dbusservice['/Temperature'] = float(data['temperature'])
            if 'humidity' in data and data['humidity'] is not None:
                self._dbusservice['/Humidity'] = float(data['humidity'])
            if 'pressure' in data and data['pressure'] is not None:
                self._dbusservice['/Pressure'] = float(data['pressure'])
        except (ValueError, TypeError) as e:
            logging.error(f"Could not process sensor value. Invalid data format. Data: {data}. Error: {e}")

class MqttHandlerForSingleSensor:
    def __init__(self, sensor_id: str, dbus_service: DbusSingleSensorService, config: configparser.ConfigParser):
        self._sensor_id = sensor_id
        self._dbus_service = dbus_service
        self._config = config
        self.client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        broker_address = config.get('DEFAULT', 'MqttBroker')
        broker_port = config.getint('DEFAULT', 'MqttPort')
        self.client.connect(broker_address, broker_port, 60)
        self.client.loop_start()

    def _on_connect(self, client, userdata, flags, rc, properties=None):
        if rc == 0:
            topic = self._config.get('DEFAULT', 'MqttTopic')
            logging.info(f"Connected to MQTT, subscribing to {topic}")
            client.subscribe(topic)

    def _on_message(self, client, userdata, msg):
        try:
            payload = json.loads(msg.payload)
            json_array_root = self._config.get('DEFAULT', 'JsonArrayRoot')
            sensor_id_key = self._config.get('DEFAULT', 'SensorIdKey')
            for sensor_data in payload.get(json_array_root, []):
                if sensor_data.get(sensor_id_key) == self._sensor_id:
                    self._dbus_service.update_values(sensor_data)
                    break
        except Exception as e:
            logging.error(f"Error processing message: {e}", exc_info=True)

def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python single_sensor.py <config_section_name>")

    sensor_section_name = sys.argv[1]
    logging.info(f"Worker process starting for sensor section: [{sensor_section_name}]")
    
    from dbus.mainloop.glib import DBusGMainLoop
    DBusGMainLoop(set_as_default=True)

    config = configparser.ConfigParser()
    config.read(os.path.join(os.path.dirname(__file__), 'config.ini'))
    
    try:
        custom_name = config.get(sensor_section_name, 'CustomName')
        device_instance = config.getint(sensor_section_name, 'DeviceInstance')
        dbus_service = DbusSingleSensorService(sensor_section_name, custom_name, device_instance)
        MqttHandlerForSingleSensor(sensor_section_name, dbus_service, config)
    except Exception as e:
        logging.critical(f"FATAL: Failed to initialize service. Error: {e}", exc_info=True)
        sys.exit(1)
    
    mainloop = GLib.MainLoop()
    mainloop.run()

if __name__ == "__main__":
    main()