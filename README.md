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

## Installation

1.  **Connect to your Venus OS device** via SSH.

2.  **Clone or copy the project files** into `/data/etc/dbus-mqtt-temperature`.

3.  **Create your configuration file**:
    ```bash
    cp config.ini.example config.ini
    ```

4.  **Edit `config.ini`** to match your MQTT broker and sensor definitions.

5.  **Make the scripts executable**:
    ```bash
    chmod +x install.sh uninstall.sh
    ```

6.  **Run the installation script**:
    ```bash
    bash install.sh
    ```
The services will start automatically.

## Expected JSON Structure

The script is designed to parse a specific JSON format: an object that contains an array of sensor objects. The MQTT message payload sent to the configured topic should look like this:

```json
{
  "sensors": [
    {
      "id": "outside",
      "temperature": 21.5,
      "humidity": 55.2,
      "pressure": 1013.2
    },
    {
      "id": "fridge",
      "temperature": 4.1
    },
    {
      "id": "engine_room",
      "temperature": 45.8,
      "humidity": 78.0
    }
  ]
}
```

-   The `"sensors"` key must match the `JsonArrayRoot` value in your `config.ini`.
-   The `"id"` key in each object must match the `SensorIdKey` value from your config. Its value (e.g., `"outside"`) must correspond to a sensor section like `[outside]` in your `config.ini`.
-   It is not necessary for every sensor object to contain all possible values (temperature, humidity, pressure). The script will only update the values it finds.

### A Note on Node-RED

This data structure is easily created using **Node-RED**, which is included in Venus OS Large firmware. You can gather data from various sources (like RuuviTags, Shelly sensors, BLE devices, etc.), use a `join` node or a `function` node to assemble them into this single array format, and then publish the complete JSON object to the MQTT topic that this service listens to.

## Troubleshooting

You can check the logs for each individual sensor. For a sensor with the ID `saloon`, the command is:
```bash
tail -f /service/dbus-mqtt-temperature-saloon/log/current | tai64nlocal
```

## Uninstallation

To completely remove all services, run the uninstaller:
```bash
bash uninstall.sh
```

## Acknowledgements

A huge thank you to **[mr-manuel](https://github.com/mr-manuel)** for the original [`venus-os_dbus-mqtt-temperature`](https://github.com/mr-manuel/venus-os_dbus-mqtt-temperature) project, which provided the foundation and inspiration for this version.