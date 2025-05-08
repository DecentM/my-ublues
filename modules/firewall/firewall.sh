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

# Remove existing services
echo "$1" | jq -c '.remove_services // [] | .[]' | while read -r service; do
    NAME=$(echo "$service" | jq -r '.name')
    SERVICE_FILE="$SERVICES_DIR/$NAME.xml"

    if [ -f "$SERVICE_FILE" ]; then
        echo "Removing custom service: $NAME"
        rm -f "$SERVICE_FILE"
    else
        echo "Service $NAME not found"
        exit 1
    fi
done

# Create custom services
echo "$1" | jq -c '.custom_services // [] | .[]' | while read -r service; do
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

# Remove existing zones
echo "$1" | jq -c '.remove_zones // [] | .[]' | while read -r zone; do
    NAME=$(echo "$zone" | jq -r '.name')
    ZONE_FILE="$ZONES_DIR/$NAME.xml"

    if [ -f "$ZONE_FILE" ]; then
        echo "Removing custom zone: $NAME"
        rm -f "$ZONE_FILE"
    else
        echo "Zone $NAME not found"
        exit 1
    fi
done

# Create custom zones
echo "$1" | jq -c '.custom_zones // [] | .[]' | while read -r zone; do
    NAME=$(echo "$zone" | jq -r '.name')
    DESC=$(echo "$zone" | jq -r '.description')
    ZONE_FILE="$ZONES_DIR/$NAME.xml"
    ensure_zone_file "$NAME"

    echo "Writing custom zone: $NAME"
    {
        echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        echo "<zone>"
        echo "  <short>$NAME</short>"
        echo "  <description>$DESC</description>"
        echo "$zone" | jq -r '.services // [] | .[] | "  <service name=\"\(.name)\"/>"'
        echo "$zone" | jq -r '.ports // [] | .[] | "  <port protocol=\"\(.protocol)\" port=\"\(.port)\"/>"'
        echo "$zone" | jq -r '.interfaces // [] | .[] | "  <interface name=\"\(.name)\"/>"'
        echo "</zone>"
    } >"$ZONE_FILE"
done

# Set default zone
echo "$1" | jq -r '.default_zone' | while read -r zone; do
    echo "Setting default zone to $zone"
    sed -i "s|^DefaultZone=.*|DefaultZone=$zone|" /etc/firewalld/firewalld.conf
done

ostree container commit
