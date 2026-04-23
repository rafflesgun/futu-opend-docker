# CMD Mode Dispatch Design

## Summary

Enhance the container startup flow so a single entrypoint dispatches
between named startup modes selected by Docker `CMD`. The image default
will be `both`, while users can also run `opend`, `mcp`, or `setup`.
This keeps the installation flow simpler while preserving a single image
entrypoint.

## Goals

- Keep one image entrypoint.
- Add `CMD ["both"]` as the default startup mode.
- Support these explicit modes:
  - `both`
  - `opend`
  - `mcp`
  - `setup`
- Improve installation/setup flow by exposing a `setup` mode that prints
  the full OpenD command with `--setup-only` and keeps the container
  alive.

## Non-Goals

- Add a separate environment-variable mode switch.
- Add a second dispatcher script.
- Automatically perform SMS login verification inside the container.
- Remove the focused helper entrypoints unless they become unnecessary
  during implementation.

## Current State

The image currently uses `entrypoint-all.sh` as the default entrypoint,
but that script only implements the combined `both` behavior. The image
does not currently define a Docker `CMD`, so users cannot select a named
mode through container arguments.

## Proposed Design

### Architecture

- Keep `ENTRYPOINT ["/usr/local/bin/entrypoint-all.sh"]`
- Add `CMD ["both"]`
- Make `entrypoint-all.sh` interpret `$1` as the mode selector

The supported modes are:

- `both`
- `opend`
- `mcp`
- `setup`

### Mode behavior

#### `both`

- validate `futu-opend.toml`
- validate `futu-mcp.toml`
- validate `keys.json`
- start OpenD
- append `--device-id "$FUTU_OPEND_DEVICE_ID"` when set
- wait for `http://127.0.0.1:22222/health`
- start MCP

#### `opend`

- validate `futu-opend.toml`
- validate `keys.json`
- start only OpenD
- append `--device-id "$FUTU_OPEND_DEVICE_ID"` when set

#### `mcp`

- validate `futu-mcp.toml`
- validate `keys.json`
- start only MCP

#### `setup`

- validate `futu-opend.toml`
- validate `keys.json`
- construct the full OpenD command with `--setup-only`
- include `--device-id "$FUTU_OPEND_DEVICE_ID"` when set
- print that full command to container logs
- keep the container alive
- do not start normal OpenD or MCP processes

### Unknown mode behavior

If the first argument is not one of the supported modes, the entrypoint
must print a clear error with the allowed values and exit non-zero.

### Documentation

Update `README.md` to show:

- default behavior via `docker run futu-opend-rs:local`
- `docker run futu-opend-rs:local opend`
- `docker run futu-opend-rs:local mcp`
- `docker run futu-opend-rs:local setup`

The docs should explain that `setup` is for login/bootstrap flow and
prints the exact OpenD `--setup-only` command needed for SMS
verification.

## Error Handling

- Fail fast on missing required files for the selected mode.
- `both` still fails if OpenD never reaches the health endpoint before
  timeout.
- `setup` must not accidentally start normal services.
- Unknown modes must fail loudly and predictably.

## Testing and Verification

Verify with:

- `sh -n` for all entrypoint scripts
- `docker compose config`
- markdown lint on updated docs/spec/plan files
- targeted inspection of dispatcher behavior for all four modes

## Scope

This change is intentionally focused on container startup UX:

- add Docker `CMD` default mode
- dispatch startup behavior from one entrypoint
- document mode-based invocation
