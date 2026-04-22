# FUTU-OpenD-rs Docker Bundle

Personal Docker deployment for `FUTU-OpenD-rs` with native `arm64`
and `amd64` builds, an HTTP MCP service, and repo-local nanobot
assets.

## What this repo provides

- one native Docker image that bundles `futu-opend`, `futu-mcp`, and `futucli`
- one compose stack with separate `opend` and `mcp` services
- a `toml`-first runtime configuration workflow under `examples/`
- repo-local nanobot MCP templates and the compliant skill package under `skills/`

## Supported architectures

- `linux/arm64`
- `linux/amd64`

The image build downloads the matching upstream `FUTU-OpenD-rs`
release for the target architecture and runs it natively. There is no
translation layer in this bundle.

## Runtime model

This repo packages the Rust-native `FUTU-OpenD-rs` runtime rather than
the legacy desktop OpenD distribution.

- `opend` runs the trading gateway and exposes:
  - native TCP on `11111`
  - REST and health endpoints on `22222`
  - gRPC on `33333`
- `mcp` runs `futu-mcp` separately and connects to `opend:11111`
- both services mount repo-local config files from `examples/`
- persistent runtime state and logs live in the named volumes
  `futu-state` and `futu-log`

The MCP service is published on `38765` and serves HTTP MCP requests at `/mcp`.

## Quick start

1. Edit `examples/futu-opend.toml` with your account, region, and
   platform settings.
1. Generate or rotate the plaintext bearer token you want MCP clients
   to send, hash that token, and store the hash plus scopes in
   `examples/keys.json`. The checked-in example token is
   `fc_replace_me`.
1. Adjust `examples/futu-mcp.toml` if you want to change the default
   MCP HTTP listen address or audit log path.
1. Run `docker compose up -d --build`.
1. Point your MCP client at `http://<host>:38765/mcp` and send the
   plaintext token in `Authorization: Bearer <token>`.

The compose stack defaults `FUTU_MCP_API_KEY` to `fc_replace_me` for the
local MCP bearer token. Keep that plaintext token aligned with the
matching `sha256:` entry in `examples/keys.json`, or override it with a
different local environment value when you launch compose.

## Configuration workflow

The runtime is configured with mounted files, not generated config or a
startup-only environment variable shim.

### `examples/futu-opend.toml`

Primary gateway configuration for `futu-opend`.

- login identity and password or password MD5
- market region such as `cn`, `hk`, or `us`
- platform such as `futunn` or `moomoo`
- listen addresses and ports for TCP, REST, and gRPC
- logging and language settings

Mounted in compose as `/etc/futu-opend/futu-opend.toml`.

### `examples/futu-mcp.toml`

Configuration for the standalone MCP service.

- upstream gateway target, defaulting to `opend:11111`
- `keys.json` path for MCP auth and capability mapping
- bearer token env supplied by compose, defaulting to `fc_replace_me`
- HTTP listen address, defaulting to `:38765`
- audit log path

Mounted in compose as `/etc/futu-opend/futu-mcp.toml`.

### `examples/keys.json`

Hashed key records and scope mapping for `futu-mcp`.

Clients send a plaintext bearer token. `futu-mcp` hashes the presented
token and compares it with the stored `hash` entries in this file.

Compose mounts the file into both containers, but the active auth check
is part of the MCP service flow rather than the `opend` gateway config.

## Compose usage

Start or rebuild the local bundle:

```bash
docker compose up -d --build
```

Build and push a multi-arch image:

```bash
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap
docker buildx build --platform linux/amd64,linux/arm64 --push -t rafflesg/futo-opend:latest .
```

If `docker buildx build` fails with `Multi-platform build is not supported
for the docker driver`, the active builder is using the plain `docker`
driver. Switch to a container-backed builder first:

```bash
docker buildx use multiarch
docker buildx inspect --bootstrap
```

Stop the stack:

```bash
docker compose down
```

Check service status:

```bash
docker compose ps
```

The default stack exposes these ports:

- `11111` for the native OpenD TCP gateway
- `22222` for the OpenD REST API and health endpoint
- `33333` for the OpenD gRPC endpoint
- `38765` for the MCP HTTP server

## MCP usage for nanobot

Nanobot can talk to the MCP service over HTTP.

- endpoint: `http://<host>:38765/mcp`
- header: `Authorization: Bearer <plaintext token>`

Bearer-token flow:

- the client keeps and sends the plaintext token
- `examples/keys.json` stores the corresponding `sha256:` hash and
  allowed scopes
- `futu-mcp` checks the presented token against those stored hashes

See:

- `nanobot/README.md` for the integration notes
- `nanobot/mcp-http-example.json` for an MCP client template
- `skills/moomooapi/SKILL.md` for the compliant market/trading
  skill package

Start with read-only scopes such as `qot:read` and `acc:read`, then
separate any simulated or live trading access into distinct keys.

## Repo layout

Important runtime and integration assets live here:

- `Dockerfile` builds the native multi-arch `FUTU-OpenD-rs` image
- `docker-compose.yaml` defines the local `opend` and `mcp` stack
- `examples/futu-opend.toml` is the gateway config template
- `examples/futu-mcp.toml` is the MCP config template
- `examples/keys.json` stores hashed MCP bearer-token entries and scopes
- `nanobot/README.md` documents nanobot MCP setup
- `nanobot/mcp-http-example.json` contains a ready-to-edit MCP HTTP
  client example
- `skills/moomooapi/SKILL.md` contains the compliant market/trading
  skill package

## Migration note

Older revisions of this repo targeted the legacy upstream OpenD
runtime. Current `main` is centered on `FUTU-OpenD-rs` only.

If you are migrating from an older checkout, update your workflow to use:

- mounted `toml` config files under `examples/`
- `examples/keys.json` for MCP auth
- the two-service compose stack with `opend` and `mcp`

If an older checkout mentions compatibility shims, generated config,
interactive verification steps, injected key files, or env-only login
startup, ignore that guidance and follow the file-mounted rs-native
workflow here instead.

## Disclaimer

This project is not affiliated with [Futu Securities International (Hong Kong) Limited](https://www.futuhk.com/).
