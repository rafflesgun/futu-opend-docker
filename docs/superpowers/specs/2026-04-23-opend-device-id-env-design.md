# OpenD Device ID Env Support Design

## Summary

Add dedicated environment-variable support for passing a persistent OpenD
device ID into the container startup command. The runtime behavior remains
config-first, with `entrypoint-opend.sh` continuing to launch `futu-opend`
from `/etc/futu-opend/futu-opend.toml`, and conditionally appending
`--device-id <value>` when `FUTU_OPEND_DEVICE_ID` is provided. The
entrypoint also requires `/etc/futu-opend/keys.json` to exist before
startup.

## Goals

- Support `docker run -e FUTU_OPEND_DEVICE_ID=...` for OpenD startup.
- Preserve the existing default startup behavior when the env var is absent.
- Keep the change minimal and localized to the existing entrypoint and docs.

## Non-Goals

- Add a generic extra-args passthrough env var.
- Validate device ID format in the shell entrypoint.
- Change MCP startup behavior.
- Change the mounted TOML config model.
- Remove the current `keys.json` startup requirement.

## Current State

The image currently starts OpenD through `script/entrypoint-opend.sh`, which
validates that `/etc/futu-opend/futu-opend.toml` and
`/etc/futu-opend/keys.json` exist and then executes:

```sh
/usr/local/bin/futu-opend --config /etc/futu-opend/futu-opend.toml
```

There is no current support for any environment variable that maps to
`--device-id`.

## Proposed Design

### Entrypoint behavior

Keep `script/entrypoint-opend.sh` as the single startup path.

- If `FUTU_OPEND_DEVICE_ID` is unset or empty, preserve current behavior.
- Keep the existing startup failure if either the config file or
  `/etc/futu-opend/keys.json` is missing.
- If `FUTU_OPEND_DEVICE_ID` is set, append:

```sh
--device-id "$FUTU_OPEND_DEVICE_ID"
```

The effective command becomes:

```sh
/usr/local/bin/futu-opend \
  --config /etc/futu-opend/futu-opend.toml \
  --device-id "$FUTU_OPEND_DEVICE_ID"
```

The script must continue to `exec` the final command so signal handling and
container shutdown semantics remain correct.

### Configuration surface

Introduce one supported runtime env var:

- `FUTU_OPEND_DEVICE_ID`: optional OpenD device ID value passed through to the
  `--device-id` CLI flag.

No additional startup env vars are introduced.

### Documentation

Update repo docs to show:

- `docker run -e FUTU_OPEND_DEVICE_ID=...`
- a Compose `environment:` example for the `opend` service

The docs should describe this as optional and maintain the current default
examples for users who do not need a fixed device ID.

## Error Handling

- Keep the existing hard failure when the config file is missing.
- Keep the existing hard failure when `keys.json` is missing.
- Treat empty or unset `FUTU_OPEND_DEVICE_ID` as no-op.
- Do not add shell-side format validation for the device ID; let `futu-opend`
  reject invalid values if necessary.

## Testing and Verification

Verify the final behavior with command-level checks:

- startup command when `FUTU_OPEND_DEVICE_ID` is absent
- startup command when `FUTU_OPEND_DEVICE_ID` is present
- startup failure when `/etc/futu-opend/keys.json` is absent
- docs examples reference the correct env var name

If no automated test harness exists for the shell entrypoint, verification can
be done by inspecting the effective command construction and running the
relevant markdown or repo validation commands already used in this project.

## Scope

This change is intentionally narrow:

- one entrypoint behavior extension
- documentation updates
- no image layout changes
- no config schema changes
