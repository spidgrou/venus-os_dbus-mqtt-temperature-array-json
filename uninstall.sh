#!/bin/bash
# Uninstaller v12.0

SERVICE_DIR_BASE="/data/etc/dbus-mqtt-temperature"
CONFIG_FILE="$SERVICE_DIR_BASE/config.ini"
LOG_DIR="/data/log/dbus-mqtt-temperature"

echo "--- Uninstalling all dbus-mqtt-temperature services ---"
SECTIONS=$(grep -E '^\[.*\]$' "$CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/' | grep -v 'DEFAULT' || true)

if [ -z "$SECTIONS" ]; then
    echo "No sensor sections found."
else
    for section in $SECTIONS; do
        SERVICE_NAME="dbus-mqtt-temperature-$section"
        SERVICE_DEST_LINK="/service/$SERVICE_NAME"
        SERVICE_SRC_DIR="$SERVICE_DIR_BASE/service-$section"

        if [ -L "$SERVICE_DEST_LINK" ]; then
            echo "Removing service link: $SERVICE_NAME"
            rm "$SERVICE_DEST_LINK"
            sleep 1
        fi
        if [ -d "$SERVICE_SRC_DIR" ]; then
            echo "Removing source directory: $SERVICE_SRC_DIR"
            rm -rf "$SERVICE_SRC_DIR"
        fi
    done
fi

# Remove the central log directory as well
if [ -d "$LOG_DIR" ]; then
    echo "Removing log directory: $LOG_DIR"
    rm -rf "$LOG_DIR"
fi

pkill -f "single_sensor.py"
echo "--- Uninstallation complete. ---"