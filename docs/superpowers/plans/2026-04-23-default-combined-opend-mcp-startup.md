# Default Combined OpenD MCP Startup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL:
> Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Docker image and Compose defaults start both
`futu-opend` and `futu-mcp` together in one container.

**Architecture:** Switch the Docker image default entrypoint to the
existing combined launcher and simplify Compose to one service that uses
that image default. Update docs so both plain `docker run` and `docker
compose up` are described as default combined-service startup paths.

**Tech Stack:** POSIX shell, Docker, Docker Compose, Markdown docs

---

## File Map

- Modify: `Dockerfile`
  - Change the default image entrypoint to the combined launcher.

- Modify: `docker-compose.yaml`
  - Collapse the current two-service stack into one service that exposes
    all ports and mounts all required config.

- Modify: `README.md`
  - Rewrite startup guidance to describe combined startup as the default.

### Task 1: Make Combined Startup the Image Default

**Files:**

- Modify: `Dockerfile`

- [ ] **Step 1: Keep the combined entrypoint copied into the image**

Ensure this copy line remains present:

```dockerfile
COPY --chmod=0755 script/entrypoint-all.sh /usr/local/bin/entrypoint-all.sh
```

- [ ] **Step 2: Change the image default entrypoint**

Replace:

```dockerfile
ENTRYPOINT ["/usr/local/bin/entrypoint-opend.sh"]
```

with:

```dockerfile
ENTRYPOINT ["/usr/local/bin/entrypoint-all.sh"]
```

### Task 2: Simplify Compose to One Service

**Files:**

- Modify: `docker-compose.yaml`

- [ ] **Step 1: Remove the separate `mcp` service**

Delete the current standalone `mcp` service block entirely.

- [ ] **Step 2: Extend the remaining `opend` service for combined mode**

Update the single remaining service so it includes:

```yaml
services:
  opend:
    build:
      context: .
      args:
        FUTU_OPEND_RS_VER: 1.4.62
    image: futu-opend-rs:local
    container_name: futu-opend
    restart: unless-stopped
    environment:
      FUTU_MCP_API_KEY: ${FUTU_MCP_API_KEY:-fc_replace_me}
    volumes:
      - ./examples/futu-opend.toml:/etc/futu-opend/futu-opend.toml:ro
      - ./examples/futu-mcp.toml:/etc/futu-opend/futu-mcp.toml:ro
      - ./examples/keys.json:/etc/futu-opend/keys.json:ro
      - futu-state:/var/lib/futu
      - futu-log:/var/log/futu
    ports:
      - "11111:11111"
      - "22222:22222"
      - "33333:33333"
      - "38765:38765"
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://127.0.0.1:22222/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 15s
```

- [ ] **Step 3: Keep named volumes unchanged**

Ensure the file still ends with:

```yaml
volumes:
  futu-state:
  futu-log:
```

### Task 3: Rewrite Runtime Documentation for New Defaults

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Rewrite runtime overview text**

Update repo descriptions that currently imply a two-service Compose stack
so they describe the default runtime as one container running both
services.

- [ ] **Step 2: Rewrite the quick-start and Compose usage sections**

Document that:

- `docker compose up -d --build` starts both OpenD and MCP in one
  container
- plain `docker run futu-opend-rs:local` also starts both services by
  default when the required files are mounted
- `FUTU_OPEND_DEVICE_ID` still applies to OpenD startup
- `FUTU_MCP_API_KEY` still controls MCP bearer-token input

- [ ] **Step 3: Update port and topology wording**

Update wording so it no longer claims:

- one Compose stack with separate `opend` and `mcp` services
- MCP runs in a separate container
- the repo uses a two-service stack by default

Replace it with wording that matches the new single-container default.

### Task 4: Verify the New Default Behavior Configuration

**Files:**

- Verify: `Dockerfile`
- Verify: `docker-compose.yaml`
- Verify: `README.md`
- Verify: `script/entrypoint-all.sh`

- [ ] **Step 1: Run shell syntax checks for entrypoints**

Run:
`sh -n script/entrypoint-opend.sh && sh -n script/entrypoint-mcp.sh &&
sh -n script/entrypoint-all.sh`

Expected: no output and exit code 0

- [ ] **Step 2: Render the new Compose config**

Run: `docker compose config`

Expected: one `opend` service renders with `FUTU_MCP_API_KEY`, both TOML
mounts, `keys.json`, and all four ports

- [ ] **Step 3: Lint updated markdown files**

Run:
`npx --yes markdownlint-cli README.md
docs/superpowers/specs/2026-04-23-default-combined-opend-mcp-startup-design.md
docs/superpowers/plans/2026-04-23-default-combined-opend-mcp-startup.md`

Expected: no markdownlint errors

- [ ] **Step 4: Review final diff for targeted files**

Run:
`git diff -- Dockerfile docker-compose.yaml README.md
docs/superpowers/specs/2026-04-23-default-combined-opend-mcp-startup-design.md
docs/superpowers/plans/2026-04-23-default-combined-opend-mcp-startup.md`

Expected: only the approved default-startup files and docs changed
