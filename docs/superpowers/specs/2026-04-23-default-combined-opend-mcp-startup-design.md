# Default Combined OpenD MCP Startup Design

## Summary

Change the image and Compose defaults so both `futu-opend` and
`futu-mcp` start together by default. The image default entrypoint will
be the combined launcher, and the Compose stack will be simplified from
two services to one service that exposes both the OpenD and MCP ports.

## Goals

- Make plain `docker run futu-opend-rs:local` start both services.
- Make `docker compose up -d` start both services in one container by
  default.
- Keep the current `FUTU_OPEND_DEVICE_ID` support in the default startup
  flow.
- Keep the existing healthcheck based on the OpenD REST health endpoint.

## Non-Goals

- Preserve the current two-container Compose topology.
- Add a separate process supervisor dependency.
- Change config file locations or port numbers.
- Remove the current `keys.json` startup requirement.

## Current State

The repo currently has:

- `entrypoint-opend.sh` for OpenD-only startup
- `entrypoint-mcp.sh` for MCP-only startup
- `entrypoint-all.sh` for explicit combined startup
- Docker default entrypoint still set to `entrypoint-opend.sh`
- Compose still modeled as separate `opend` and `mcp` services

## Proposed Design

### Architecture

- Change the Docker image default entrypoint to
  `/usr/local/bin/entrypoint-all.sh`.
- Simplify `docker-compose.yaml` to a single `opend` service that uses
  the image default entrypoint.
- Mount all required config into that single container:
  - `/etc/futu-opend/futu-opend.toml`
  - `/etc/futu-opend/futu-mcp.toml`
  - `/etc/futu-opend/keys.json`
- Publish all required ports from the single service:
  - `11111`
  - `22222`
  - `33333`
  - `38765`

### Runtime behavior

The default container startup path becomes the combined launcher:

- validate `futu-opend.toml`
- validate `futu-mcp.toml`
- validate `keys.json`
- start `futu-opend`
- append `--device-id "$FUTU_OPEND_DEVICE_ID"` when set
- wait for `http://127.0.0.1:22222/health`
- start `futu-mcp`
- keep both processes managed inside one container

### Compose behavior

`docker-compose.yaml` will move from two services to one.

The remaining service:

- builds the local image
- mounts both TOML files and `keys.json`
- keeps the named state and log volumes
- keeps the OpenD healthcheck
- sets `FUTU_MCP_API_KEY`
- publishes all OpenD and MCP ports from the same container

### Documentation

Update `README.md` to describe:

- `docker run` starting both services by default
- Compose starting both services in one container by default
- the required config files for the single-container setup
- the published ports and MCP endpoint location

Remove or rewrite wording that still describes Compose as a two-service
stack.

## Error Handling

- Fail fast if any required config file is missing.
- Fail fast if OpenD does not become healthy before the timeout.
- If either child process exits unexpectedly, terminate the other and
  exit non-zero.
- On container stop, terminate both processes and wait for them.

## Testing and Verification

Verify with:

- `sh -n` for all entrypoint scripts
- `docker compose config` to confirm the single-service Compose file
  renders correctly
- markdown lint on updated docs/spec/plan files
- targeted diff review of Dockerfile, Compose, README, and entrypoint
  files

## Scope

This change is intentionally focused on default startup behavior:

- switch Docker default entrypoint to combined mode
- simplify Compose to one service
- update docs to match the new defaults
- no new runtime dependency beyond the existing shell + curl approach
