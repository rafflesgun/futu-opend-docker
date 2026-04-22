# Combined OpenD MCP Container Design

## Summary

Add an explicit single-container startup mode that runs both
`futu-opend` and `futu-mcp` inside one container for `docker run`
workflows. The existing default image behavior remains unchanged: the
image still starts `opend` by default, and Compose continues to run
`opend` and `mcp` as separate services.

## Goals

- Support a single `docker run` flow that starts both `opend` and `mcp`.
- Preserve the existing default image entrypoint behavior.
- Keep the current Compose topology unchanged.
- Reuse the current config file and env var model.

## Non-Goals

- Replace the existing two-service Compose stack.
- Add a full process supervisor dependency.
- Change the current `opend` or `mcp` binary flags beyond existing repo
  behavior.
- Change mounted config file locations.

## Current State

The image currently supports one process per container:

- default entrypoint: `entrypoint-opend.sh`
- alternate entrypoint for MCP: `entrypoint-mcp.sh`

The Compose stack runs two containers and uses `depends_on` plus the
OpenD health endpoint before starting `mcp`.

## Proposed Design

### Architecture

Add a new explicit combined launcher:

- `script/entrypoint-all.sh`

Users opt into combined mode by overriding the entrypoint in
`docker run`, for example:

```bash
docker run --entrypoint /usr/local/bin/entrypoint-all.sh ...
```

The image default entrypoint remains `entrypoint-opend.sh`.

### Entrypoint behavior

The combined entrypoint will:

- validate `/etc/futu-opend/futu-opend.toml`
- validate `/etc/futu-opend/futu-mcp.toml`
- validate `/etc/futu-opend/keys.json`
- start `futu-opend` first
- append `--device-id "$FUTU_OPEND_DEVICE_ID"` when the env var is set
- wait for `http://127.0.0.1:22222/health` to become healthy
- start `futu-mcp --config /etc/futu-opend/futu-mcp.toml`
- trap `SIGTERM` and `SIGINT`
- stop both child processes on shutdown
- exit non-zero if startup fails or a child exits unexpectedly

### Readiness model

The script should reuse the same health endpoint the Compose stack
already trusts:

- `http://127.0.0.1:22222/health`

It should poll until healthy or until a fixed timeout elapses. Timeout
should produce a clear error and shut down any running child process.

### Documentation

Update `README.md` to show:

- the new combined `docker run --entrypoint ...` invocation
- required mounts for `futu-opend.toml`, `futu-mcp.toml`, and
  `keys.json`
- required port mappings for both OpenD and MCP endpoints
- optional `FUTU_OPEND_DEVICE_ID`

## Error Handling

- Fail fast if required files are missing.
- Fail fast if `opend` never reaches healthy state within the timeout.
- If `futu-opend` exits before `mcp` starts, stop and return non-zero.
- If either process exits after both are running, terminate the other and
  return non-zero.
- On container stop, send termination to both children and wait.

## Testing and Verification

Verify with:

- `sh -n` for all entrypoint scripts
- `docker compose config` to confirm existing Compose behavior still
  renders
- markdown lint on updated docs/spec/plan files
- targeted inspection of the combined entrypoint command flow and signal
  handling

## Scope

This change is intentionally narrow:

- one new combined entrypoint script
- one Dockerfile copy change
- README updates
- no Compose behavior changes by default
