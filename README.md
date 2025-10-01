# Venus OS DBus MQTT Sensors (JSON Array Version)

> **Disclaimer:** This is a fork of the excellent [`venus-os_dbus-mqtt-temperature` project by mr-manuel](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature). This version is specifically adapted to handle a **JSON array of sensors** from a single MQTT topic.

This service allows you to integrate multiple sensors into Victron's Venus OS using a single MQTT topic. Each sensor will appear as a separate device in the Venus OS Device List and on the VRM portal.

## Prerequisites

1.  **Venus OS Large Firmware (Recommended):** This script is best run on a "Large" firmware version of Venus OS, as it includes the necessary package manager (`opkg`, `pip`).

2.  **Python Libraries:** The script requires two external Python libraries. To install them, connect to your Venus OS device via SSH and run the following commands:
    ```bash
    # Update the package list
    opkg update
    
    # Install the Python package manager, pip
    opkg install python3-pip
    
    # Use pip to install the required libraries
    pip install paho-mqtt pygobject
    ```
    This script uses the `velib_python` library that is already included in Venus OS, so no additional Victron-specific libraries need to be copied.

## Installation

1.  **Connect to your Venus OS device** via SSH.

2.  **Clone or copy the project files** into `/data/etc/dbus-mqtt-temperature`.

3.  **Create your configuration file**:
    ```bash
    cp config.ini.example config.ini
    ```

4.  **Edit `config.ini`** to match your MQTT broker and sensor definitions.
    ```bash
    nano config.ini
    ```

5.  **Make the scripts executable**:
    ```bash
    chmod +x install.sh uninstall.sh
    ```

6.  **Run the installation script**:
    ```bash
    bash install.sh
    ```

The services will start automatically.

## Uninstallation

To completely remove all services, run the uninstaller:
```bash
bash uninstall.sh
```

## Acknowledgements

A huge thank you to **[mr-manuel](https://github.com/mr-manuel)** for the original [`venus-os_dbus-mqtt-temperature`](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature) project, which provided the foundation and inspiration for this version.