# CMD Mode Dispatch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL:
> Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Docker `CMD`-driven startup modes so one image entrypoint
can run `both`, `opend`, `mcp`, or `setup`.

**Architecture:** Keep `entrypoint-all.sh` as the single image
entrypoint, add `CMD ["both"]` in the Dockerfile, and make the script
dispatch behavior from the first CLI argument. Update docs so mode-based
invocation is explicit and the setup flow is easy to follow.

**Tech Stack:** POSIX shell, Docker, Docker Compose, Markdown docs

---

## File Map

- Modify: `script/entrypoint-all.sh`
  - Add mode dispatch and setup-mode behavior.

- Modify: `Dockerfile`
  - Add `CMD ["both"]`.

- Modify: `README.md`
  - Document the mode-based container interface.

### Task 1: Add Mode Dispatch to the Entrypoint

**Files:**

- Modify: `script/entrypoint-all.sh`

- [ ] **Step 1: Keep the existing helpers and validations reusable**

Refactor the current script so validation and command construction are
organized into small shell functions for:

- validating OpenD inputs
- validating MCP inputs
- building the OpenD command with optional `--device-id`
- running combined mode

- [ ] **Step 2: Dispatch on the first argument**

Implement mode selection with the first argument defaulting to `both`:

```sh
MODE=${1:-both}

case "$MODE" in
  both)
    run_both
    ;;
  opend)
    run_opend
    ;;
  mcp)
    run_mcp
    ;;
  setup)
    run_setup
    ;;
  *)
    echo "Unsupported mode: $MODE" >&2
    echo "Supported modes: both, opend, mcp, setup" >&2
    exit 1
    ;;
esac
```

- [ ] **Step 3: Implement `opend` mode**

`opend` mode must:

- validate `futu-opend.toml`
- validate `keys.json`
- execute only the OpenD command

with the same optional `--device-id` handling already used elsewhere.

- [ ] **Step 4: Implement `mcp` mode**

`mcp` mode must:

- validate `futu-mcp.toml`
- validate `keys.json`
- execute only `futu-mcp --config "$MCP_CONFIG_PATH"`

- [ ] **Step 5: Implement `setup` mode**

`setup` mode must:

- validate `futu-opend.toml`
- validate `keys.json`
- build the full OpenD command with `--setup-only`
- include `--device-id "$FUTU_OPEND_DEVICE_ID"` when set
- print the exact full command to logs
- keep the container alive
- never start normal OpenD or MCP processes

Use a simple long-running wait such as:

```sh
echo "Setup mode active; container will stay alive for SMS verification."
while :; do
  sleep 3600
done
```

- [ ] **Step 6: Keep `both` mode behavior unchanged**

Preserve the current combined behavior:

- start OpenD
- wait for health
- start MCP
- terminate both on shutdown or child failure

- [ ] **Step 7: Verify shell syntax after refactor**

Run: `sh -n script/entrypoint-all.sh`

Expected: no output and exit code 0

### Task 2: Add the Docker Default CMD

**Files:**

- Modify: `Dockerfile`

- [ ] **Step 1: Keep the combined entrypoint as Docker ENTRYPOINT**

Ensure this remains:

```dockerfile
ENTRYPOINT ["/usr/local/bin/entrypoint-all.sh"]
```

- [ ] **Step 2: Add the default mode CMD**

Add:

```dockerfile
CMD ["both"]
```

so plain `docker run futu-opend-rs:local` uses combined mode by default.

### Task 3: Document Mode-Based Usage

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Document the default mode**

Explain that the image now uses:

- entrypoint: `entrypoint-all.sh`
- default command: `both`

- [ ] **Step 2: Add explicit mode examples**

Document these examples:

```bash
docker run --rm futu-opend-rs:local
docker run --rm futu-opend-rs:local opend
docker run --rm futu-opend-rs:local mcp
docker run --rm futu-opend-rs:local setup
```

Add the required mount and env examples for realistic usage.

- [ ] **Step 3: Explain `setup` mode clearly**

Document that `setup` mode:

- prints the full OpenD command with `--setup-only`
- is intended for login/bootstrap with SMS verification
- keeps the container alive
- does not start the normal services

### Task 4: Verify the Mode Dispatch Changes

**Files:**

- Verify: `script/entrypoint-all.sh`
- Verify: `Dockerfile`
- Verify: `README.md`

- [ ] **Step 1: Run shell syntax checks for all entrypoints**

Run:
`sh -n script/entrypoint-opend.sh && sh -n script/entrypoint-mcp.sh &&
sh -n script/entrypoint-all.sh`

Expected: no output and exit code 0

- [ ] **Step 2: Render Compose config**

Run: `docker compose config`

Expected: Compose still renders with the default combined container
configuration

- [ ] **Step 3: Lint updated markdown files**

Run:
`npx --yes markdownlint-cli README.md
docs/superpowers/specs/2026-04-23-cmd-mode-dispatch-design.md
docs/superpowers/plans/2026-04-23-cmd-mode-dispatch.md`

Expected: no markdownlint errors

- [ ] **Step 4: Review final diff for targeted files**

Run:
`git diff -- Dockerfile README.md script/entrypoint-all.sh
docs/superpowers/specs/2026-04-23-cmd-mode-dispatch-design.md
docs/superpowers/plans/2026-04-23-cmd-mode-dispatch.md`

Expected: only the approved mode-dispatch files and docs changed
