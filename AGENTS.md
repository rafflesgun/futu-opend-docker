# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-22T00:00:00Z
**Commit:** Task-7-worktree
**Branch:** main

## OVERVIEW

Local Docker and Compose packaging for `futu-opend-rs` and `futu-mcp`,
with mounted examples and nanobot integration assets.

## STRUCTURE

```text
.
├── Dockerfile              # Multi-stage build for futu-opend-rs binaries
├── docker-compose.yaml     # Local single-container stack
├── examples/               # Example TOML config and key material
├── skills/
│   └── moomooapi/          # Compliant market/trading skill package
├── script/
│   ├── entrypoint-opend.sh # Opend container entrypoint
│   ├── entrypoint-mcp.sh   # MCP container entrypoint
├── nanobot/                # MCP client templates and prompt assets
└── README.md               # Local build and usage guide
```

## WHERE TO LOOK

- Adjust image build: `Dockerfile`
  Notes: `FUTU_OPEND_RS_VER`, multi-arch download
- Modify startup: `script/entrypoint-all.sh`
  Notes: starts `futu-opend`, waits for health, then starts `futu-mcp`
- Single-process entrypoints: `script/entrypoint-opend.sh`,
  `script/entrypoint-mcp.sh`
  Notes: retained as focused launchers for individual services
- Compose examples: `docker-compose.yaml`, `examples/*.toml`
  Notes: local stack and mounted config
- Skill package: `skills/moomooapi/SKILL.md`
  Notes: compliant market/trading skill entry point
- Nanobot assets: `nanobot/`
  Notes: MCP client example and prompt asset
- User guide: `README.md`
  Notes: local build, compose, and MCP usage details

## CONVENTIONS

- **Multi-stage Docker**: Builder downloads release tarball, final image
  installs only runtime deps
- **Default root runtime**: Images run as the container default root user
  to avoid bind-mount permission failures on host directories
- **Compose-mounted config**: Runtime config comes from
  `examples/*.toml` and `examples/keys.json`
- **Local-only workflow**: this repo is intended for local build and
  local Compose use

## ANTI-PATTERNS (THIS PROJECT)

- **NEVER** hardcode secrets — mount config and key files instead
- **NEVER** commit real key material or account credentials
- **NEVER** remove the OpenD readiness gate before starting `mcp`
  inside the combined entrypoint without replacing it with an equivalent
  readiness check

## UNIQUE STYLES

- **Config-first runtime**: TOML files are mounted into `/etc/futu-opend`
- **Combined default startup**: the image default entrypoint starts
  `futu-opend` first, then starts `futu-mcp` after the health endpoint is
  ready
- **Healthcheck**: Compose probes `http://127.0.0.1:22222/health` on the
  single combined container
- **Shared logs/state**: Named volumes back `/var/lib/futu` and `/var/log/futu`

## COMMANDS

```bash
# Build locally
docker build --platform linux/arm64 -t futu-opend-rs:final .

# Render compose config
docker compose config

# Run with compose
docker compose up -d

# Inspect logs
docker compose logs --no-color opend
```

## NOTES

- **Default MCP token**: compose defaults `FUTU_MCP_API_KEY` to
  `fc_replace_me` unless overridden locally
- **Key material required**: `examples/keys.json` must exist for local startup
- **Skill entry point**: repo skill assets live under
  `skills/moomooapi/`; use `skills/moomooapi/SKILL.md` as the valid
  entry point, not a Markdown note under `nanobot/`
- **Startup depends on valid upstream credentials and network access**
- **Disclaimer**: Not affiliated with Futu Securities
