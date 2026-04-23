#!/bin/sh
set -eu

OPEND_CONFIG_PATH=/etc/futu-opend/futu-opend.toml
MCP_CONFIG_PATH=/etc/futu-opend/futu-mcp.toml
KEYS_PATH=/etc/futu-opend/keys.json
OPEND_HEALTH_URL=http://127.0.0.1:22222/health
OPEND_HEALTH_RETRIES=30
OPEND_HEALTH_DELAY=1

validate_opend_inputs() {
  if [ ! -f "$OPEND_CONFIG_PATH" ]; then
    echo "Missing futu-opend config: $OPEND_CONFIG_PATH" >&2
    exit 1
  fi

  if [ ! -f "$KEYS_PATH" ]; then
    echo "Missing API key file: $KEYS_PATH" >&2
    exit 1
  fi
}

validate_mcp_inputs() {
  if [ ! -f "$MCP_CONFIG_PATH" ]; then
    echo "Missing futu-mcp config: $MCP_CONFIG_PATH" >&2
    exit 1
  fi

  if [ ! -f "$KEYS_PATH" ]; then
    echo "Missing API key file: $KEYS_PATH" >&2
    exit 1
  fi
}

terminate_children() {
  trap - INT TERM

  if [ -n "${MCP_PID:-}" ]; then
    kill "$MCP_PID" 2>/dev/null || true
  fi

  if [ -n "${OPEND_PID:-}" ]; then
    kill "$OPEND_PID" 2>/dev/null || true
  fi
}

run_opend() {
  validate_opend_inputs
  set -- /usr/local/bin/futu-opend --config "$OPEND_CONFIG_PATH"

  if [ -n "${FUTU_OPEND_DEVICE_ID:-}" ]; then
    set -- "$@" --device-id "$FUTU_OPEND_DEVICE_ID"
  fi

  exec "$@"
}

run_mcp() {
  validate_mcp_inputs
  exec /usr/local/bin/futu-mcp --config "$MCP_CONFIG_PATH"
}

run_setup() {
  validate_opend_inputs

  set -- /usr/local/bin/futu-opend --config "$OPEND_CONFIG_PATH"

  if [ -n "${FUTU_OPEND_DEVICE_ID:-}" ]; then
    set -- "$@" --device-id "$FUTU_OPEND_DEVICE_ID"
  fi

  set -- "$@" --setup-only

  echo "OpenD setup command: $*"
  echo "Setup mode active; container will stay alive for SMS verification."

  while :; do
    sleep 3600
  done
}

run_both() {
  validate_opend_inputs
  validate_mcp_inputs

  set -- /usr/local/bin/futu-opend --config "$OPEND_CONFIG_PATH"

  if [ -n "${FUTU_OPEND_DEVICE_ID:-}" ]; then
    set -- "$@" --device-id "$FUTU_OPEND_DEVICE_ID"
  fi

  "$@" &
  OPEND_PID=$!

  trap terminate_children INT TERM

  i=0
  while [ "$i" -lt "$OPEND_HEALTH_RETRIES" ]; do
    if curl -fsS "$OPEND_HEALTH_URL" >/dev/null 2>&1; then
      break
    fi

    if ! kill -0 "$OPEND_PID" 2>/dev/null; then
      wait "$OPEND_PID"
      exit 1
    fi

    i=$((i + 1))
    sleep "$OPEND_HEALTH_DELAY"
  done

  if [ "$i" -eq "$OPEND_HEALTH_RETRIES" ]; then
    echo "Timed out waiting for OpenD health endpoint: $OPEND_HEALTH_URL" >&2
    terminate_children
    wait "$OPEND_PID" 2>/dev/null || true
    exit 1
  fi

  /usr/local/bin/futu-mcp --config "$MCP_CONFIG_PATH" &
  MCP_PID=$!

  while :; do
    if ! kill -0 "$OPEND_PID" 2>/dev/null; then
      wait "$OPEND_PID"
      terminate_children
      wait "$MCP_PID" 2>/dev/null || true
      exit 1
    fi

    if ! kill -0 "$MCP_PID" 2>/dev/null; then
      wait "$MCP_PID"
      terminate_children
      wait "$OPEND_PID" 2>/dev/null || true
      exit 1
    fi

    sleep 1
  done
}

MODE=${1:-both}

case "$MODE" in
  both)
    run_both
    ;;
  opend)
    run_opend
    ;;
  mcp)
    run_mcp
    ;;
  setup)
    run_setup
    ;;
  *)
    echo "Unsupported mode: $MODE" >&2
    echo "Supported modes: both, opend, mcp, setup" >&2
    exit 1
    ;;
esac
