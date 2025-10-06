#!/bin/bash
# Uninstaller - Cleans everything

SERVICE_DIR_BASE="/data/etc/dbus-mqtt-temperature"
CONFIG_FILE="$SERVICE_DIR_BASE/config.ini"
LOG_DIR="/data/log/dbus-mqtt-temperature"

echo "--- Uninstalling all dbus-mqtt-temperature services ---"
SECTIONS=$(grep -E '^\[.*\]$' "$CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/' | grep -v 'DEFAULT' || true)

if [ ! -z "$SECTIONS" ]; then
    for section in $SECTIONS; do
        SERVICE_NAME="dbus-mqtt-temperature-$section"
        SERVICE_DEST_LINK="/service/$SERVICE_NAME"
        SERVICE_SRC_DIR="$SERVICE_DIR_BASE/service-$section"

        if [ -L "$SERVICE_DEST_LINK" ]; rm "$SERVICE_DEST_LINK"; fi
        if [ -d "$SERVICE_SRC_DIR" ]; rm -rf "$SERVICE_SRC_DIR"; fi
    done
fi

if [ -d "$LOG_DIR" ]; rm -rf "$LOG_DIR"; fi
pkill -f "single_sensor.py"
echo "--- Uninstallation complete. ---"