# Venus OS DBus MQTT Sensors (JSON Array Version)

> **Disclaimer:** This is a fork of the excellent [`venus-os_dbus-mqtt-temperature` project by mr-manuel](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature). This version is specifically adapted to handle a **JSON array of sensors** from a single MQTT topic.

This service allows you to integrate multiple sensors into Victron's Venus OS using a single MQTT topic. Each sensor will appear as a separate device in the Venus OS Device List and on the VRM portal.

## Prerequisites

1.  **Venus OS Large Firmware (Recommended):** This script is best run on a "Large" firmware version of Venus OS, as it includes the necessary package manager (`opkg`, `pip`).

2.  **Required Packages:** Before installing, you may need some common tools. Connect to your Venus OS device via SSH and run the following commands:
    ```bash
    # Update the package list
    opkg update
    
    # Install unzip and the Python package manager, pip
    opkg install unzip python3-pip
    
    # Use pip3 to install the required libraries
    pip3 install paho-mqtt pygobject
    ```

## Installation

1.  **Connect to your Venus OS device** via SSH.

2.  **Navigate to the `/data/etc` directory.**
    ```bash
    cd /data/etc
    ```

3.  **Download the project.**
    ```bash
    wget -O main.zip https://github.com/spidgrou/venus-os_dbus-mqtt-temperature-array-json/archive/refs/heads/main.zip
    ```

4.  **Unzip the project and clean up.**
    ```bash
    unzip main.zip
    mv venus-os_dbus-mqtt-temperature-array-json-main dbus-mqtt-temperature
    rm main.zip
    ```

5.  **Enter the project directory.**
    ```bash
    cd dbus-mqtt-temperature
    ```

6.  **Create your configuration file.**
    ```bash
    cp config.ini.example config.ini
    ```

7.  **Edit `config.ini`** to match your MQTT broker and sensor definitions.

8.  **Make the scripts executable.**
    ```bash
    chmod +x install.sh uninstall.sh
    ```

9.  **Run the installation script.**
    ```bash
    bash install.sh
    ```
The services will start automatically.

## Troubleshooting

If your sensors do not appear in the Device List, follow these steps to diagnose the issue.

#### 1. Check if the Service is Running

For each sensor, a separate service is created. You can check its status using the `svstat` command. Replace `[your_sensor_id]` with the actual ID from your `config.ini` (e.g., `fridge`).

```bash
svstat /service/dbus-mqtt-temperature-[your_sensor_id]
```

**Example:**
```bash
svstat /service/dbus-mqtt-temperature-fridge
```

-   **GOOD:** The output shows `up` with a stable process ID (PID) and an increasing uptime (e.g., `/service/dbus-mqtt-temperature-fridge: up (pid 12345) 60 seconds`). This means the script is running without crashing.
-   **BAD:** The output shows `down`, or the PID number changes every few seconds. This means the script is in a crash loop. If this is the case, proceed to the next step.

#### 2. Check the Log File

All services write their output and errors to a central log file. This is the best place to find out why a service is crashing or not receiving data.

```bash
tail -f /data/log/dbus-mqtt-temperature/current | tai64nlocal
```

Look for:
-   **Success messages:** Lines containing `Worker process starting`, `D-Bus service successfully registered`, and `Connected to MQTT`.
-   **Data messages:** A line like `Updating values for...` every time an MQTT message is received.
-   **Error messages:** Any line containing `ERROR` or `Traceback` will tell you exactly what is wrong (e.g., a typo in `config.ini`, a problem connecting to the MQTT broker, or an issue with the JSON format).

## Uninstallation

To completely remove all services, run the uninstaller from the project directory:
```bash
bash uninstall.sh
```

## Acknowledgements

A huge thank you to **[mr-manuel](https://github.com/mr-manuel)** for the original [`venus-os_dbus-mqtt-temperature`](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature) project, which provided the foundation and inspiration for this version.