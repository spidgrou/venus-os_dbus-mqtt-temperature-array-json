# Venus OS DBus MQTT Sensors (JSON Array Version)

> **Disclaimer:** This is a fork of the excellent [`venus-os_dbus-mqtt-temperature` project by mr-manuel](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature). This version is specifically adapted to handle a **JSON array of sensors** from a single MQTT topic.

This service allows you to integrate multiple sensors into Victron's Venus OS using a single MQTT topic. Each sensor will appear as a separate device in the Venus OS Device List and on the VRM portal.

## Architecture (v12.0+)

**Single process, single MQTT connection** — all sensors are managed by one Python process:

- One MQTT connection with auto-reconnect and Last Will & Testament
- MQTT I/O integrated in the GLib main loop (no background threads)
- Each sensor is a separate D-Bus service (`com.victronenergy.temperature.mqtt_*`)
- Graceful shutdown on SIGTERM/SIGINT

This reduces RAM usage and eliminates the risk of zombie processes (compared to the old v11.x approach with one process per sensor).

## MQTT Topic & Bridge Health

| Topic | Description |
|---|---|
| `<your_topic>` | JSON array of sensors (your configured topic) |
| `<your_topic>/bridge/online` | Health check: 1 = running, 0 = offline |

## Prerequisites

The installation script will automatically try to install the required packages (`curl`, `unzip`). If you encounter issues, or if you are running a minimal firmware, you can install the dependencies manually by connecting to your Venus OS device via SSH and running these commands:

```bash
# Update the package list
opkg update

# Install required tools and the Python package manager
opkg install curl unzip python3-pip

# Use pip3 to install the required Python libraries
pip3 install paho-mqtt pygobject
```

## Installation

This installation method automatically downloads and installs the latest stable release.

1.  **Connect to your Venus OS device** via SSH.
2.  **Download and execute the installer script.**
    Copy and paste the following two commands into your SSH terminal:

    ```bash
    wget -O /tmp/download.sh https://raw.githubusercontent.com/spidgrou/venus-os_dbus-mqtt-temperature-array-json/main/download.sh
    ```
    ```bash
    bash /tmp/download.sh
    ```

3.  **Navigate to the new directory and configure the service.**
    ```bash
    cd /data/etc/dbus-mqtt-temperature
    ```
    ```bash
    # Create your configuration file from the example
    cp config.ini.example config.ini

    # Edit the file with your settings
    nano config.ini
    ```

4.  **Make the local scripts executable and run the final installation.**
    ```bash
    chmod +x install.sh uninstall.sh
    bash install.sh
    ```

The service will start automatically. **If you are upgrading from v11.x**, the old per-sensor services will remain — stop them manually:
```bash
for s in /service/dbus-mqtt-temperature-*; do svc -d $s; done
```

## Applying Configuration Changes

If you modify your `config.ini` file (for example, to add a new sensor), restart the service:

```bash
svc -t /service/dbus-mqtt-temperature
```

## Troubleshooting

If your sensors do not appear, follow these steps to diagnose the issue.

#### 1. Check if the Service is Running

```bash
svstat /service/dbus-mqtt-temperature
```

- **GOOD:** The output shows `up` with a stable process ID (PID) and an increasing uptime.
- **BAD:** The output shows `down`, or the PID changes every few seconds — check the logs.

#### 2. Check the Log File

```bash
tail -f /data/log/dbus-mqtt-temperature/current | tai64nlocal
```

Look for:
- **Success messages:** Lines like `Initialized N D-Bus sensor services`, `Connected to MQTT`.
- **Data messages:** Lines showing `Updating values for...` when MQTT data arrives.
- **Error messages:** Any line containing `ERROR` or `Traceback`.

## Uninstallation

```bash
cd /data/etc/dbus-mqtt-temperature
bash uninstall.sh
```

## Upgrading from v11.x (per-sensor processes)

The old architecture launched one Python process per sensor (5 processes, 5 MQTT connections).
v12.0+ uses a single process — lower RAM, no zombie threads.

**Migration:**
1. Install v12.0 (see Installation above)
2. Stop old services: `for s in /service/dbus-mqtt-temperature-*; do svc -d $s; done`
3. Verify new service: `svstat /service/dbus-mqtt-temperature`

Your `config.ini` remains compatible — no changes needed.

## Changelog

### v12.0 (2026-05-12)
- **Single process architecture** — one Python instance manages all sensors (reduced RAM, simpler logging).
- **MQTT integrated into GLib main loop** — removed per-process `loop_start()` threads.
- **Auto-reconnect** — automatic retry every 5 seconds when MQTT connection drops.
- **LWT (Last Will & Testament)** — broker publishes `<topic>/bridge/online = 0` on unexpected crash.
- **Health check** — `<topic>/bridge/online` topic: 1 on connect, 0 on disconnect.
- **Graceful shutdown** — SIGTERM/SIGINT publishes offline state and sets `/Connected = 0` on D-Bus.
- **D-Bus /Connected updated** — reflects actual MQTT connection state (was always 1 in v11.x).

### v11.4
- Initial release: per-sensor processes, MQTT thread per sensor.

## Acknowledgements

A huge thank you to **[mr-manuel](https://github.com/mr-manuel)** for the original project.
