#!/bin/bash
# Uninstaller v12.0 — Removes the single multi-sensor service

SERVICE_NAME="dbus-mqtt-temperature"
SERVICE_DEST_LINK="/service/$SERVICE_NAME"
SERVICE_SRC_DIR="/data/etc/dbus-mqtt-temperature/service"
LOG_DIR="/data/log/dbus-mqtt-temperature"

echo "Stopping service..."
svc -d "$SERVICE_DEST_LINK" 2>/dev/null
sleep 1

echo "Removing service link..."
if [ -L "$SERVICE_DEST_LINK" ]; then
    rm "$SERVICE_DEST_LINK"
fi

echo "Removing service directory..."
if [ -d "$SERVICE_SRC_DIR" ]; then
    rm -rf "$SERVICE_SRC_DIR"
fi

echo "Removing log directory..."
if [ -d "$LOG_DIR" ]; then
    rm -rf "$LOG_DIR"
fi

echo ""
echo "Uninstall complete."
echo "Note: Your config.ini, temperature_bridge.py and single_sensor.py remain in"
echo "      /data/etc/dbus-mqtt-temperature/"
echo "      Remove them manually if desired: rm -rf /data/etc/dbus-mqtt-temperature"
echo ""
echo "If you had old individual sensor services, remove them with:"
echo "  svc -d /service/dbus-mqtt-temperature-outside"
echo "  svc -d /service/dbus-mqtt-temperature-engine_room"
echo "  svc -d /service/dbus-mqtt-temperature-fridge"
echo "  svc -d /service/dbus-mqtt-temperature-freezer"
echo "  svc -d /service/dbus-mqtt-temperature-saloon"
