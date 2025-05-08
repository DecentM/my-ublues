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
    TARGET=$(echo "$zone" | jq -r '.target')
    ZONE_FILE="$ZONES_DIR/$NAME.xml"
    ensure_zone_file "$NAME"

    echo "Writing custom zone: $NAME"
    {
        echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        echo "<zone>"
        echo "  <short>$NAME</short>"
        echo "  <description>$DESC</description>"
        echo "  <target>$TARGET</target>"
        echo "$zone" | jq -r '.services // [] | .[] | "  <service name=\"\(.name)\"/>"'
        echo "$zone" | jq -r '.ports // [] | .[] | "  <port protocol=\"\(.protocol)\" port=\"\(.port)\"/>"'
        echo "$zone" | jq -r '.interfaces // [] | .[] | "  <interface name=\"\(.name)\"/>"'
        echo "</zone>"
    } >"$ZONE_FILE"
done

# # Bind services to zones
# echo "$1" | jq -c '.services // [] | .[]' | while read -r svc; do
#     ZONE=$(echo "$svc" | jq -r '.zone')
#     NAME=$(echo "$svc" | jq -r '.name')
#     ENABLED=$(echo "$svc" | jq -r '.enabled')
#     ensure_zone_file "$ZONE"
#     ZONE_FILE="$ZONES_DIR/$ZONE.xml"

#     if [ "$ENABLED" = "true" ]; then
#         if ! grep -q "<service name=\"$NAME\"" "$ZONE_FILE"; then
#             echo "Enabling service $NAME in zone $ZONE"
#             sed -i "/<\/zone>/i \  <service name=\"$NAME\"/>" "$ZONE_FILE"
#         fi
#     else
#         echo "Disabling service $NAME in zone $ZONE"
#         # Remove matching service entry
#         sed -i "/<service name=\"$NAME\"\/>/d" "$ZONE_FILE"
#     fi
# done

# # Bind ports to zones
# echo "$1" | jq -c '.ports // [] | .[]' | while read -r port; do
#     ZONE=$(echo "$port" | jq -r '.zone')
#     PORT=$(echo "$port" | jq -r '.port')
#     PROTO=$(echo "$port" | jq -r '.protocol')
#     ENABLED=$(echo "$port" | jq -r '.enabled')
#     ensure_zone_file "$ZONE"
#     ZONE_FILE="$ZONES_DIR/$ZONE.xml"

#     if [ "$ENABLED" = "true" ]; then
#         if ! grep -q "port=\"$PORT\" protocol=\"$PROTO\"" "$ZONE_FILE"; then
#             echo "Enabling port $PORT/$PROTO in zone $ZONE"
#             sed -i "/<\/zone>/i \  <port port=\"$PORT\" protocol=\"$PROTO\"/>" "$ZONE_FILE"
#         fi
#     else
#         echo "Disabling port $PORT/$PROTO in zone $ZONE"
#         # Remove matching port entry
#         sed -i "/<port port=\"$PORT\" protocol=\"$PROTO\"\/>/d" "$ZONE_FILE"
#     fi
# done

# # Bind interfaces to zones
# echo "$1" | jq -c '.interfaces // [] | .[]' | while read -r iface; do
#     ZONE=$(echo "$iface" | jq -r '.zone')
#     INTERFACE=$(echo "$iface" | jq -r '.interface')
#     ENABLED=$(echo "$iface" | jq -r '.enabled')
#     ensure_zone_file "$ZONE"
#     ZONE_FILE="$ZONES_DIR/$ZONE.xml"

#     if [ "$ENABLED" = "true" ]; then
#         if ! grep -q "<interface name=\"$INTERFACE\"" "$ZONE_FILE"; then
#             echo "Enabling interface $INTERFACE in zone $ZONE"
#             sed -i "/<\/zone>/i \  <interface name=\"$INTERFACE\"/>" "$ZONE_FILE"
#         fi
#     else
#         echo "Disabling interface $INTERFACE in zone $ZONE"
#         # Remove matching interface entry
#         sed -i "/<interface name=\"$INTERFACE\"\/>/d" "$ZONE_FILE"
#     fi
# done

# Set default zone
echo "$1" | jq -r '.default_zone' | while read -r zone; do
    echo "Setting default zone to $zone"
    sed -i "s|^DefaultZone=.*|DefaultZone=$zone|" /etc/firewalld/firewalld.conf
done

ostree container commit
