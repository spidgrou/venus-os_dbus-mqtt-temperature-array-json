#!/bin/bash
# Uninstaller v13.0 - Cleans up services and rc.local entry

SERVICE_DIR_BASE="/data/etc/dbus-mqtt-temperature"
CONFIG_FILE="$SERVICE_DIR_BASE/config.ini"
LOG_DIR="/data/log/dbus-mqtt-temperature"
RC_LOCAL_FILE="/data/rc.local"

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
            rm "$SERVICE_DEST_LINK"
            sleep 1
        fi
        if [ -d "$SERVICE_SRC_DIR" ]; then
            rm -rf "$SERVICE_SRC_DIR"
        fi
    done
fi

if [ -d "$LOG_DIR" ]; then
    rm -rf "$LOG_DIR"
fi

pkill -f "single_sensor.py"

echo "--- Removing startup entry from $RC_LOCAL_FILE... ---"
if [ -f "$RC_LOCAL_FILE" ]; then
    sed -i -e "/# Start dbus-mqtt-temperature services on boot/d" "$RC_LOCAL_FILE"
    sed -i -e "/(sleep 60; \/data\/etc\/dbus-mqtt-temperature\/install.sh &)/d" "$RC_LOCAL_FILE"
    echo "Startup entry removed (if it existed)."
fi

echo "--- Uninstallation complete. ---"