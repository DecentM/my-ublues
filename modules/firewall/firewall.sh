#!/usr/bin/env sh

set -eux

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

# Add ports
echo "$1" | jq -r '.ports[] |
    "firewall-cmd --permanent --zone=\(.zone) --add-port=\(.port)/\(.protocol)"
' | while read -r cmd; do
    eval "$cmd"
done

# Create custom services
echo "$1" | jq -c '.custom_services[]' | while read -r svc; do
    NAME=$(echo "$svc" | jq -r '.name')
    DESC=$(echo "$svc" | jq -r '.description')
    PORTS=$(echo "$svc" | jq -c '.ports')

    SERVICE_FILE="/usr/lib/firewalld/services/$NAME.xml"

    {
        echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        echo "<service>"
        echo "  <short>$NAME</short>"
        echo "  <description>$DESC</description>"
        echo "$PORTS" | jq -r '.[] | "  <port protocol=\"" + .protocol + "\" port=\"" + (.port | tostring) + "\"/>"'
        echo "</service>"
    } >"$SERVICE_FILE"

    chmod 644 "$SERVICE_FILE"
done

# Enable/disable services
echo "$1" jq -r '
.services[] |
(if .enabled then
    "firewall-cmd --permanent --zone=\(.zone) --add-service=\(.name)"
else
    "firewall-cmd --permanent --zone=\(.zone) --remove-service=\(.name)"
end)
' | while read -r cmd; do
    eval "$cmd"
done

ostree container commit
