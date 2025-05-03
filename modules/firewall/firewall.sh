#!/usr/bin/env sh

set -eu

if [ -z "$CONFIG_DIRECTORY" ]; then
    echo "CONFIG_DIRECTORY is not set"
    exit 1
fi

if ! command -v jq >/dev/null; then
    echo "jq is not installed"
    exit 1
fi

if ! command -v firewall-cmd >/dev/null; then
    echo "firewalld is not installed (is this the right image?)"
    exit 1
fi

ZONES_DIR="/usr/lib/firewalld/zones"
SERVICES_DIR="/usr/lib/firewalld/services"

ensure_zone_file() {
    ZONE_NAME="$1"
    ZONE_FILE="$ZONES_DIR/$ZONE_NAME.xml"
    if [ ! -f "$ZONE_FILE" ]; then
        echo "Creating new zone: $ZONE_NAME"
        cat >"$ZONE_FILE" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>$ZONE_NAME</short>
</zone>
EOF
    fi
}

# Add ports
echo "$1" | jq -c '.ports[]' | while read -r port; do
    ZONE=$(echo "$port" | jq -r '.zone')
    PORT=$(echo "$port" | jq -r '.port')
    PROTO=$(echo "$port" | jq -r '.protocol')
    ensure_zone_file "$ZONE"
    ZONE_FILE="$ZONES_DIR/$ZONE.xml"

    # Add port only if not present
    if ! grep -q "port=\"$PORT\" protocol=\"$PROTO\"" "$ZONE_FILE"; then
        echo "Adding port $PORT/$PROTO to zone $ZONE"
        sed -i "/<\/zone>/i \  <port port=\"$PORT\" protocol=\"$PROTO\"/>" "$ZONE_FILE"
    fi
done

# Create custom services
echo "$1" | jq -c '.custom_services[]' | while read -r service; do
    NAME=$(echo "$service" | jq -r '.name')
    DESC=$(echo "$service" | jq -r '.description')
    SERVICE_FILE="$SERVICES_DIR/$NAME.xml"

    echo "Writing custom service: $NAME"
    {
        echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        echo "<service>"
        echo "  <short>$NAME</short>"
        echo "  <description>$DESC</description>"
        echo "$service" | jq -r '.ports[] | "  <port protocol=\"\(.protocol)\" port=\"\(.port)\"/>"'
        echo "</service>"
    } >"$SERVICE_FILE"
done

# Enable/disable services
echo "$1" | jq -c '.services[]' | while read -r svc; do
    ZONE=$(echo "$svc" | jq -r '.zone')
    NAME=$(echo "$svc" | jq -r '.name')
    ENABLED=$(echo "$svc" | jq -r '.enabled')
    ensure_zone_file "$ZONE"
    ZONE_FILE="$ZONES_DIR/$ZONE.xml"

    if [ "$ENABLED" = "true" ]; then
        if ! grep -q "<service name=\"$NAME\"" "$ZONE_FILE"; then
            echo "Enabling service $NAME in zone $ZONE"
            sed -i "/<\/zone>/i \  <service name=\"$NAME\"/>" "$ZONE_FILE"
        fi
    else
        echo "Disabling service $NAME in zone $ZONE"
        # Remove matching service entry
        sed -i "/<service name=\"$NAME\"\/>/d" "$ZONE_FILE"
    fi
done

ostree container commit
