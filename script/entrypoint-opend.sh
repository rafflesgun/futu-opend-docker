#!/bin/sh
set -eu

CONFIG_PATH=/etc/futu-opend/futu-opend.toml

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Missing futu-opend config: $CONFIG_PATH" >&2
  exit 1
fi

exec /usr/local/bin/futu-opend --config "$CONFIG_PATH"
