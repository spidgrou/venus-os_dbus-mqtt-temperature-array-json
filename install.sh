#!/bin/bash
# Installer v12.0 — Single process multi-sensor

SERVICE_DIR_BASE="/data/etc/dbus-mqtt-temperature"
PYTHON_SCRIPT_PATH="$SERVICE_DIR_BASE/temperature_bridge.py"
CONFIG_FILE="$SERVICE_DIR_BASE/config.ini"

# Verifica se c'è ancora la vecchia configurazione
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    echo "Did you copy config.ini.example to config.ini?"
    exit 1
fi

# Crea la directory del service
SERVICE_NAME="dbus-mqtt-temperature"
SERVICE_SRC_DIR="$SERVICE_DIR_BASE/service"
SERVICE_DEST_LINK="/service/$SERVICE_NAME"

mkdir -p "$SERVICE_SRC_DIR"

echo "Creating service: $SERVICE_NAME"

cat > "$SERVICE_SRC_DIR/run" << 'RUNEOF'
#!/bin/bash
# Wait for D-Bus broker
echo "Waiting for D-Bus broker..."
while ! dbus-send --system --print-reply --dest=org.freedesktop.DBus \
      / org.freedesktop.DBus.ListNames > /dev/null 2>&1; do
    sleep 1
done
echo "D-Bus ready, starting temperature bridge."
exec /data/etc/dbus-mqtt-temperature/temperature_bridge.py \
     2>&1 | multilog t s25000 n10 /data/log/dbus-mqtt-temperature
RUNEOF

chmod 755 "$SERVICE_SRC_DIR/run"

# Crea la directory di log
mkdir -p /data/log/dbus-mqtt-temperature

# Collega il service
if [ ! -L "$SERVICE_DEST_LINK" ]; then
    ln -s "$SERVICE_SRC_DIR" "$SERVICE_DEST_LINK"
fi

echo "---"
echo "Installation complete."
echo ""
echo "To start the service:"
echo "  svc -u /service/$SERVICE_NAME"
echo ""
echo "To check status:"
echo "  svstat /service/$SERVICE_NAME"
echo ""
echo "To view logs:"
echo "  tail -f /data/log/dbus-mqtt-temperature/current | tai64nlocal"
echo ""
echo "NOTE: If you had individual sensor services from the old version,"
echo "      stop/remove them with: svc -d /service/dbus-mqtt-temperature-*"
