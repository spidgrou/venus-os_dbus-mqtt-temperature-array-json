# Venus OS DBus MQTT Sensors (JSON Array Version)

> **Disclaimer:** This is a fork of the excellent [`venus-os_dbus-mqtt-temperature` project by mr-manuel](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature). This version is specifically adapted to handle a **JSON array of sensors** from a single MQTT topic.

This service allows you to integrate multiple sensors into Victron's Venus OS using a single MQTT topic. Each sensor will appear as a separate device in the Venus OS Device List and on the VRM portal.

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
The services will start automatically.

## Applying Configuration Changes

If you modify your `config.ini` file (for example, to add a new sensor), you need to restart the services for the changes to take effect.

#### Recommended Method: Re-install the services

This is the safest and most reliable way, as it correctly handles adding and removing sensors.

```bash
# Navigate to the project directory
cd /data/etc/dbus-mqtt-temperature

# Run the uninstaller first
bash uninstall.sh

# Then, run the installer again
bash install.sh
```

#### Advanced Method: Restarting a single service

If you only changed the `CustomName` of a sensor, you can restart just that service. Replace `[your_sensor_id]` with the actual ID (e.g., `fridge`).

```bash
svc -t /service/dbus-mqtt-temperature-[your_sensor_id]
```

## Troubleshooting

If your sensors do not appear, follow these steps to diagnose the issue.

#### 1. Check if the Service is Running

Check the status of a specific service using the `svstat` command. Replace `[your_sensor_id]` with the ID from your `config.ini`.

**Example:**
```bash
svstat /service/dbus-mqtt-temperature-fridge
```

-   **GOOD:** The output shows `up` with a stable process ID (PID) and an increasing uptime (e.g., `... up (pid 12345) 60 seconds`). This means the script is running correctly.
-   **BAD:** The output shows `down`, or the PID number changes every few seconds. This means the script is in a crash loop. Proceed to the next step.

#### 2. Check the Log File

All services write their output and errors to a central log file. This is the best place to find out what is wrong.

```bash
tail -f /data/log/dbus-mqtt-temperature/current | tai64nlocal
```

Look for:
-   **Success messages:** Lines like `Worker process starting`, `D-Bus service successfully registered`, and `Connected to MQTT`.
-   **Data messages:** A line like `Updating values for...` when an MQTT message is received.
-   **Error messages:** Any line containing `ERROR` or `Traceback` will tell you exactly what is wrong.

## Uninstallation

To completely remove all services, run the uninstaller from the project directory:
```bash
cd /data/etc/dbus-mqtt-temperature
bash uninstall.sh
```

## Acknowledgements
A huge thank you to **[mr-manuel](https://github.com/mr-manuel)** for the original project.