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

CA_NAME=$(echo "$1" | jq -r 'try .["name"]')

if [ -z "$CA_NAME" ]; then
    echo '"name" is not provided'
    exit 1
fi

filepath="$CONFIG_DIRECTORY/ca/$CA_NAME/$CA_NAME.crt"

if [ ! -f "$filepath" ]; then
    printf 'CA "%s" does not exist at %s\n' "$CA_NAME" "$filepath"
    exit 1
fi

targetpath="/usr/share/pki/ca-trust-source/anchors/$CA_NAME.crt"

if [ -f "$targetpath" ]; then
    printf 'CA "%s" is already installed at %s\n' "$CA_NAME" "$targetpath"
    exit 0
fi

cp "$filepath" "$targetpath"

update-ca-trust

ostree container commit
