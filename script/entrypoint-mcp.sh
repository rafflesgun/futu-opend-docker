#!/bin/sh
set -eu

CONFIG_PATH=/etc/futu-opend/futu-mcp.toml
KEYS_PATH=/etc/futu-opend/keys.json

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Missing futu-mcp config: $CONFIG_PATH" >&2
  exit 1
fi

if [ ! -f "$KEYS_PATH" ]; then
  echo "Missing API key file: $KEYS_PATH" >&2
  exit 1
fi

exec /usr/local/bin/futu-mcp --config "$CONFIG_PATH"
