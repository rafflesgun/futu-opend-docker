# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-22T00:00:00Z
**Commit:** Task-7-worktree
**Branch:** main

## OVERVIEW

Docker containerization for `futu-opend-rs` and `futu-mcp` with Docker Compose examples, multi-arch image builds, and GHCR publishing workflows.

## STRUCTURE

```text
.
├── Dockerfile              # Multi-stage build for futu-opend-rs binaries
├── docker-compose.yaml     # Local opend + MCP stack
├── examples/               # Example TOML config, env file, and key material
├── opend_version.json      # Pinned futu-opend-rs release metadata
├── script/
│   ├── entrypoint-opend.sh # Opend container entrypoint
│   ├── entrypoint-mcp.sh   # MCP container entrypoint
└── .github/workflows/      # CI: publish, lint, auto-merge
```

## WHERE TO LOOK

| Task               | Location                                  | Notes                                      |
| ------------------ | ----------------------------------------- | ------------------------------------------ |
| Adjust image build | `Dockerfile`                              | `FUTU_OPEND_RS_VER`, multi-arch download   |
| Modify startup     | `script/entrypoint-opend.sh`              | Starts `futu-opend` from TOML config       |
| Start MCP service  | `script/entrypoint-mcp.sh`                | Starts `futu-mcp` from TOML config         |
| Change CI          | `.github/workflows/publish.yml`           | Publish pipeline for container images      |
| Compose examples   | `docker-compose.yaml`, `examples/*.toml`  | Local stack and mounted config             |
| Lint hooks         | `.pre-commit-config.yaml`, `.github/workflows/lint.yml` | Local and CI lint entrypoints |

## CONVENTIONS

- **Multi-stage Docker**: Builder downloads release tarball, final image installs only runtime deps
- **Non-root user**: All images run as `futu` user (created at build)
- **Compose-mounted config**: Runtime config comes from `examples/*.toml` and `examples/keys.json`
- **Release pinning**: `opend_version.json` records the tracked upstream release used by automation and docs

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

# Prepare example env and render compose config
cp examples/.env.example examples/.env
docker compose config

# Run with compose
docker compose up -d

# Inspect logs
docker compose logs --no-color opend mcp
```

## NOTES

- **Example env file**: `examples/.env.example` can be copied to `examples/.env` for local compose flows
- **Key material required**: `examples/keys.json` must exist for local startup
- **Startup depends on valid upstream credentials and network access**
- **Linting**: run `pre-commit run --all-files` when `pre-commit` is installed locally
- **Disclaimer**: Not affiliated with Futu Securities
