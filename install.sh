#!/bin/bash
# Installer v12.3 - Fast and Smart wait for D-Bus

SERVICE_DIR_BASE="/data/etc/dbus-mqtt-temperature"
PYTHON_SCRIPT_PATH="$SERVICE_DIR_BASE/single_sensor.py"
CONFIG_FILE="$SERVICE_DIR_BASE/config.ini"
LOG_DIR="/data/log/dbus-mqtt-temperature"
LOG_FILE="$LOG_DIR/current"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

SECTIONS=$(grep -E '^\[.*\]$' "$CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/' | grep -v 'DEFAULT')
if [ -z "$SECTIONS" ]; then
    echo "No sensor sections found."
    exit 1
fi

echo "Found sensor sections: $SECTIONS"

for section in $SECTIONS; do
    echo "--- Installing service for sensor: [$section] ---"
    
    SERVICE_NAME="dbus-mqtt-temperature-$section"
    SERVICE_SRC_DIR="$SERVICE_DIR_BASE/service-$section"
    SERVICE_DEST_LINK="/service/$SERVICE_NAME"
    
    mkdir -p "$SERVICE_SRC_DIR"
    
    # --- LA MODIFICA CHIAVE E' QUI ---
    # Sostituiamo il vecchio comando con uno molto più veloce.
    # Questo attende solo che il D-Bus broker sia attivo.
    echo "#!/bin/bash" > "$SERVICE_SRC_DIR/run"
    echo "" >> "$SERVICE_SRC_DIR/run"
    echo "# Wait intelligently for the D-Bus broker to be available" >> "$SERVICE_SRC_DIR/run"
    echo "echo \"Waiting for D-Bus broker...\"" >> "$SERVICE_SRC_DIR/run"
    echo "while ! dbus-send --system --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames > /dev/null 2>&1; do" >> "$SERVICE_SRC_DIR/run"
    echo "    sleep 1" >> "$SERVICE_SRC_DIR/run"
    echo "done" >> "$SERVICE_SRC_DIR/run"
    echo "echo \"D-Bus ready, starting script.\"" >> "$SERVICE_SRC_DIR/run"
    echo "" >> "$SERVICE_SRC_DIR/run"
    echo "exec python3 -u \"$PYTHON_SCRIPT_PATH\" \"$section\" >> \"$LOG_FILE\" 2>&1" >> "$SERVICE_SRC_DIR/run"
    chmod 755 "$SERVICE_SRC_DIR/run"

    if [ ! -L "$SERVICE_DEST_LINK" ]; then
        ln -s "$SERVICE_SRC_DIR" "$SERVICE_DEST_LINK"
    fi
    echo "Installation for [$section] complete."
done

echo "--- All services installed successfully. ---"