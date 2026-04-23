#!/bin/sh
set -eu

CONFIG_PATH=/etc/futu-opend/futu-opend.toml
KEYS_PATH=/etc/futu-opend/keys.json

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Missing futu-opend config: $CONFIG_PATH" >&2
  exit 1
fi

if [ ! -f "$KEYS_PATH" ]; then
  echo "Missing API key file: $KEYS_PATH" >&2
  exit 1
fi

set -- /usr/local/bin/futu-opend --config "$CONFIG_PATH" --rest-keys-file "$KEYS_PATH" --grpc-keys-file "$KEYS_PATH" --ws-keys-file "$KEYS_PATH"

if [ -n "${FUTU_OPEND_DEVICE_ID:-}" ]; then
  set -- "$@" --device-id "$FUTU_OPEND_DEVICE_ID"
fi

exec "$@"
