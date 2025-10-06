#!/bin/bash
# Installer - Stable direct file logging, no rc.local

SERVICE_DIR_BASE="/data/etc/dbus-mqtt-temperature"
PYTHON_SCRIPT_PATH="$SERVICE_DIR_BASE/single_sensor.py"
CONFIG_FILE="$SERVICE_DIR_BASE/config.ini"
LOG_DIR="/data/log/dbus-mqtt-temperature"
LOG_FILE="$LOG_DIR/current"

# Create the central log directory
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

SECTIONS=$(grep -E '^\[.*\]$' "$CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/' | grep -v 'DEFAULT')
if [ -z "$SECTIONS" ]; then
    echo "No sensor sections found in $CONFIG_FILE."
    exit 1
fi

echo "Found sensor sections: $SECTIONS"

for section in $SECTIONS; do
    echo "--- Installing service for sensor: [$section] ---"
    
    SERVICE_NAME="dbus-mqtt-temperature-$section"
    SERVICE_SRC_DIR="$SERVICE_DIR_BASE/service-$section"
    SERVICE_DEST_LINK="/service/$SERVICE_NAME"
    
    mkdir -p "$SERVICE_SRC_DIR"
    
    # The run script now appends all output directly to our central log file.
    # A 30-second delay is added to ensure the system is fully booted.
    echo "#!/bin/bash" > "$SERVICE_SRC_DIR/run"
    echo "sleep 30" >> "$SERVICE_SRC_DIR/run"
    echo "exec python3 -u \"$PYTHON_SCRIPT_PATH\" \"$section\" >> \"$LOG_FILE\" 2>&1" >> "$SERVICE_SRC_DIR/run"
    chmod 755 "$SERVICE_SRC_DIR/run"

    if [ ! -L "$SERVICE_DEST_LINK" ]; then
        echo "Creating service link: $SERVICE_DEST_LINK"
        ln -s "$SERVICE_SRC_DIR" "$SERVICE_DEST_LINK"
    else
        echo "Service link already exists."
    fi
    echo "Installation for [$section] complete."
done

echo "--- All services installed successfully. ---"