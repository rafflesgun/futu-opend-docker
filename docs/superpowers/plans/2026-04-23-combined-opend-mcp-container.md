# Combined OpenD MCP Container Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL:
> Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an explicit single-container mode that starts both
`futu-opend` and `futu-mcp` from one `docker run` invocation.

**Architecture:** Add a new combined entrypoint script that validates the
required files, starts `futu-opend`, waits for its health endpoint, then
starts `futu-mcp`. Keep the current default image entrypoint and Compose
behavior unchanged, and document the combined mode as an explicit
opt-in entrypoint override.

**Tech Stack:** POSIX shell, Docker, Docker Compose, Markdown docs

---

## File Map

- Create: `script/entrypoint-all.sh`
  - Combined launcher for `futu-opend` and `futu-mcp`.

- Modify: `Dockerfile`
  - Copy the new combined entrypoint into the image.

- Modify: `README.md`
  - Document the explicit single-container `docker run` flow.

### Task 1: Add Combined Entrypoint

**Files:**

- Create: `script/entrypoint-all.sh`

- [ ] **Step 1: Mirror the existing validation inputs**

The new script should validate the same mounted file paths already used
across the repo:

```sh
OPEND_CONFIG_PATH=/etc/futu-opend/futu-opend.toml
MCP_CONFIG_PATH=/etc/futu-opend/futu-mcp.toml
KEYS_PATH=/etc/futu-opend/keys.json
```

- [ ] **Step 2: Implement combined startup and signal handling**

Create the script with this structure:

```sh
#!/bin/sh
set -eu

OPEND_CONFIG_PATH=/etc/futu-opend/futu-opend.toml
MCP_CONFIG_PATH=/etc/futu-opend/futu-mcp.toml
KEYS_PATH=/etc/futu-opend/keys.json
OPEND_HEALTH_URL=http://127.0.0.1:22222/health
OPEND_HEALTH_RETRIES=30
OPEND_HEALTH_DELAY=1

terminate() {
  trap - INT TERM
  if [ -n "${MCP_PID:-}" ]; then
    kill "$MCP_PID" 2>/dev/null || true
  fi
  if [ -n "${OPEND_PID:-}" ]; then
    kill "$OPEND_PID" 2>/dev/null || true
  fi
}

if [ ! -f "$OPEND_CONFIG_PATH" ]; then
  echo "Missing futu-opend config: $OPEND_CONFIG_PATH" >&2
  exit 1
fi

if [ ! -f "$MCP_CONFIG_PATH" ]; then
  echo "Missing futu-mcp config: $MCP_CONFIG_PATH" >&2
  exit 1
fi

if [ ! -f "$KEYS_PATH" ]; then
  echo "Missing API key file: $KEYS_PATH" >&2
  exit 1
fi

set -- /usr/local/bin/futu-opend --config "$OPEND_CONFIG_PATH"

if [ -n "${FUTU_OPEND_DEVICE_ID:-}" ]; then
  set -- "$@" --device-id "$FUTU_OPEND_DEVICE_ID"
fi

"$@" &
OPEND_PID=$!

trap terminate INT TERM

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
  terminate
  wait "$OPEND_PID" 2>/dev/null || true
  exit 1
fi

/usr/local/bin/futu-mcp --config "$MCP_CONFIG_PATH" &
MCP_PID=$!

while :; do
  if ! kill -0 "$OPEND_PID" 2>/dev/null; then
    wait "$OPEND_PID"
    terminate
    wait "$MCP_PID" 2>/dev/null || true
    exit 1
  fi

  if ! kill -0 "$MCP_PID" 2>/dev/null; then
    wait "$MCP_PID"
    terminate
    wait "$OPEND_PID" 2>/dev/null || true
    exit 1
  fi

  sleep 1
done
```

- [ ] **Step 3: Verify the new script parses**

Run: `sh -n script/entrypoint-all.sh`
Expected: no output and exit code 0

### Task 2: Ship the New Entrypoint in the Image

**Files:**

- Modify: `Dockerfile`

- [ ] **Step 1: Copy the new script into the image**

Add this line next to the existing entrypoint copies:

```dockerfile
COPY --chmod=0755 script/entrypoint-all.sh /usr/local/bin/entrypoint-all.sh
```

- [ ] **Step 2: Verify the default entrypoint stays unchanged**

Ensure the Dockerfile still ends with:

```dockerfile
ENTRYPOINT ["/usr/local/bin/entrypoint-opend.sh"]
```

### Task 3: Document Combined Single-Container Mode

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Add a combined `docker run` example**

Document an explicit opt-in flow like this near the existing runtime
usage section:

```bash
docker run --rm \
  --entrypoint /usr/local/bin/entrypoint-all.sh \
  -e FUTU_MCP_API_KEY=fc_replace_me \
  -e FUTU_OPEND_DEVICE_ID=your-stable-device-id \
  -v "$PWD/examples/futu-opend.toml:/etc/futu-opend/futu-opend.toml:ro" \
  -v "$PWD/examples/futu-mcp.toml:/etc/futu-opend/futu-mcp.toml:ro" \
  -v "$PWD/examples/keys.json:/etc/futu-opend/keys.json:ro" \
  -p 11111:11111 \
  -p 22222:22222 \
  -p 33333:33333 \
  -p 38765:38765 \
  futu-opend-rs:local
```

- [ ] **Step 2: Explain required files and startup order**

Document that combined mode requires:

- `futu-opend.toml`
- `futu-mcp.toml`
- `keys.json`

Also document that the combined entrypoint waits for OpenD health before
starting MCP.

- [ ] **Step 3: Keep Compose guidance unchanged**

Clarify that Compose remains the default two-container deployment path,
while the combined entrypoint is only for single-container `docker run`
usage.

### Task 4: Verify the Combined Mode Changes

**Files:**

- Verify: `script/entrypoint-all.sh`
- Verify: `Dockerfile`
- Verify: `README.md`

- [ ] **Step 1: Run shell syntax checks for all entrypoints**

Run:
`sh -n script/entrypoint-opend.sh && sh -n script/entrypoint-mcp.sh &&
sh -n script/entrypoint-all.sh`
Expected: no output and exit code 0

- [ ] **Step 2: Render Compose config to confirm no regression**

Run: `docker compose config`
Expected: config renders successfully with the existing two-service stack

- [ ] **Step 3: Lint updated markdown files**

Run:
`npx --yes markdownlint-cli README.md
docs/superpowers/specs/2026-04-23-combined-opend-mcp-container-design.md
docs/superpowers/plans/2026-04-23-combined-opend-mcp-container.md`
Expected: no markdownlint errors

- [ ] **Step 4: Review final diff for targeted files**

Run:
`git diff -- Dockerfile README.md script/entrypoint-all.sh
docs/superpowers/specs/2026-04-23-combined-opend-mcp-container-design.md
docs/superpowers/plans/2026-04-23-combined-opend-mcp-container.md`
Expected: only the approved combined-mode files and docs changed
