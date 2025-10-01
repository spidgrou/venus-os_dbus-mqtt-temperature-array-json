# Venus OS DBus MQTT Sensors (JSON Array Version)

> **Disclaimer:** This is a fork of the excellent [`venus-os_dbus-mqtt-temperature` project by mr-manuel](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature). This version is specifically adapted to handle a **JSON array of sensors** from a single MQTT topic.

This service allows you to integrate multiple sensors into Victron's Venus OS using a single MQTT topic.

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

The services will start automatically.

## Prerequisites

The installation script will automatically try to install the required packages (`curl`, `jq`, `unzip`, `python3-pip`). If you encounter issues, you can install them manually:
```bash
opkg update
opkg install curl jq unzip python3-pip
pip3 install paho-mqtt pygobject
```

## Uninstallation

To completely remove all services, run the uninstaller from the project directory:
```bash
# Navigate to the directory first
cd /data/etc/dbus-mqtt-temperature

# Run the uninstaller
bash uninstall.sh
```

## Acknowledgements
A huge thank you to **[mr-manuel](https://github.com/mr-manuel)** for the original project.