#!/bin/bash
# Installer v13.0 - Automatically handles boot persistence via rc.local

SERVICE_DIR_BASE="/data/etc/dbus-mqtt-temperature"
PYTHON_SCRIPT_PATH="$SERVICE_DIR_BASE/single_sensor.py"
CONFIG_FILE="$SERVICE_DIR_BASE/config.ini"
LOG_DIR="/data/log/dbus-mqtt-temperature"
LOG_FILE="$LOG_DIR/current"

# --- PART 1: Service Installation ---

echo "--- Installing services... ---"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

SECTIONS=$(grep -E '^\[.*\]$' "$CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/' | grep -v 'DEFAULT')
if [ -z "$SECTIONS" ]; then
    echo "No sensor sections found in config.ini. Aborting."
    exit 1
fi

for section in $SECTIONS; do
    SERVICE_NAME="dbus-mqtt-temperature-$section"
    SERVICE_SRC_DIR="$SERVICE_DIR_BASE/service-$section"
    SERVICE_DEST_LINK="/service/$SERVICE_NAME"
    
    mkdir -p "$SERVICE_SRC_DIR"
    
    echo "#!/bin/bash" > "$SERVICE_SRC_DIR/run"
    echo "# Wait for the system to be ready. D-Bus can take a while." >> "$SERVICE_SRC_DIR/run"
    echo "sleep 30" >> "$SERVICE_SRC_DIR/run"
    echo "exec python3 -u \"$PYTHON_SCRIPT_PATH\" \"$section\" >> \"$LOG_FILE\" 2>&1" >> "$SERVICE_SRC_DIR/run"
    chmod 755 "$SERVICE_SRC_DIR/run"

    if [ ! -L "$SERVICE_DEST_LINK" ]; then
        ln -s "$SERVICE_SRC_DIR" "$SERVICE_DEST_LINK"
    fi
done

echo "Services installed."

# --- PART 2: Boot Persistence via rc.local ---

echo "--- Setting up automatic start on boot... ---"

RC_LOCAL_FILE="/data/rc.local"
STARTUP_COMMAND="/data/etc/dbus-mqtt-temperature/install.sh &"
SLEEP_COMMAND="sleep 60" # A delay before installation runs at boot

# Create rc.local if it doesn't exist
if [ ! -f "$RC_LOCAL_FILE" ]; then
    echo "#!/bin/bash" > "$RC_LOCAL_FILE"
    echo "" >> "$RC_LOCAL_FILE"
    echo "exit 0" >> "$RC_LOCAL_FILE"
    chmod 755 "$RC_LOCAL_FILE"
    echo "Created $RC_LOCAL_FILE."
fi

# Check if our command is already in rc.local
if grep -q -F "$STARTUP_COMMAND" "$RC_LOCAL_FILE"; then
    echo "Startup command already exists in $RC_LOCAL_FILE. No changes needed."
else
    echo "Adding startup command to $RC_LOCAL_FILE."
    # Use sed to insert the command before the final 'exit 0'
    # This is safer than just appending.
    sed -i -e '$i\'$'\n'"# Start dbus-mqtt-temperature services on boot"  "$RC_LOCAL_FILE"
    sed -i -e '$i\'"($SLEEP_COMMAND; $STARTUP_COMMAND)" "$RC_LOCAL_FILE"
    echo "Startup command added."
fi

echo "--- Installation complete. ---"