# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-22T00:00:00Z
**Commit:** Task-7-worktree
**Branch:** main

## OVERVIEW

Local Docker and Compose packaging for `futu-opend-rs` and `futu-mcp`, with mounted examples and nanobot integration assets.

## STRUCTURE

```text
.
├── Dockerfile              # Multi-stage build for futu-opend-rs binaries
├── docker-compose.yaml     # Local opend + MCP stack
├── examples/               # Example TOML config and key material
├── script/
│   ├── entrypoint-opend.sh # Opend container entrypoint
│   ├── entrypoint-mcp.sh   # MCP container entrypoint
├── nanobot/                # MCP client templates and prompt assets
└── README.md               # Local build and usage guide
```

## WHERE TO LOOK

| Task               | Location                                  | Notes                                      |
| ------------------ | ----------------------------------------- | ------------------------------------------ |
| Adjust image build | `Dockerfile`                             | `FUTU_OPEND_RS_VER`, multi-arch download     |
| Modify startup     | `script/entrypoint-opend.sh`             | Starts `futu-opend` from TOML config         |
| Start MCP service  | `script/entrypoint-mcp.sh`               | Starts `futu-mcp` from TOML config           |
| Compose examples   | `docker-compose.yaml`, `examples/*.toml` | Local stack and mounted config               |
| Nanobot assets     | `nanobot/`                               | MCP client example and prompt asset          |
| User guide         | `README.md`                              | Local build, compose, and MCP usage details |

## CONVENTIONS

- **Multi-stage Docker**: Builder downloads release tarball, final image installs only runtime deps
- **Non-root user**: All images run as `futu` user (created at build)
- **Compose-mounted config**: Runtime config comes from `examples/*.toml` and `examples/keys.json`
- **Local-only workflow**: this repo is intended for local build and local Compose use

## ANTI-PATTERNS (THIS PROJECT)

- **NEVER** run containers as root — `USER futu` enforced
- **NEVER** hardcode secrets — mount config and key files instead
- **NEVER** commit real key material or account credentials
- **NEVER** remove the health dependency between `mcp` and `opend` without replacing readiness checks

## UNIQUE STYLES

- **Config-first runtime**: TOML files are mounted into `/etc/futu-opend`
- **Healthcheck**: Compose probes `http://127.0.0.1:22222/health` before starting `mcp`
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
docker compose logs --no-color opend mcp
```

## NOTES

- **Default MCP token**: compose defaults `FUTU_MCP_API_KEY` to `fc_replace_me` unless overridden locally
- **Key material required**: `examples/keys.json` must exist for local startup
- **Startup depends on valid upstream credentials and network access**
- **Disclaimer**: Not affiliated with Futu Securities
