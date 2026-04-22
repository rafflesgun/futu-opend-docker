# OpenD Device ID Env Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL:
> Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow `docker run` and Compose users to pass a fixed OpenD
device ID through `FUTU_OPEND_DEVICE_ID`, which the container maps to
`futu-opend --device-id` at startup.

**Architecture:** Extend the existing `script/entrypoint-opend.sh`
startup path so it conditionally appends `--device-id` while preserving
the current config-first invocation, the current `keys.json` startup
requirement, and `exec` behavior. Update repository documentation to
show the new optional env var in both `docker run` and Compose usage
without changing the default stack behavior.

**Tech Stack:** POSIX shell entrypoint, Docker, Docker Compose, Markdown docs

---

## File Map

- Modify: `script/entrypoint-opend.sh`
  - Add conditional handling for `FUTU_OPEND_DEVICE_ID`.

- Modify: `README.md`
  - Document `docker run` and Compose usage of `FUTU_OPEND_DEVICE_ID`.

- Optional modify: `docker-compose.yaml`
  - Only if a commented example is needed to keep docs and sample
    config aligned.

### Task 1: Update OpenD Entrypoint

**Files:**

- Modify: `script/entrypoint-opend.sh`

- [ ] **Step 1: Read the current entrypoint and preserve its constraints**

Current behavior to preserve:

```sh
#!/bin/sh
set -eu

CONFIG_PATH=/etc/futu-opend/futu-opend.toml
KEYS_PATH=/etc/futu-opend/keys.json

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Missing futu-opend config: $CONFIG_PATH" >&2
  exit 1
fi

if [ ! -f "$KEYS_PATH" ]; then
  echo "Missing API key file: $KEYS_PATH" >&2
  exit 1
fi

exec /usr/local/bin/futu-opend --config "$CONFIG_PATH"
```

- [ ] **Step 2: Implement minimal conditional device ID support**

Replace the final `exec` path with command construction that keeps quoting
safe and avoids changing behavior when the env var is unset:

```sh
#!/bin/sh
set -eu

CONFIG_PATH=/etc/futu-opend/futu-opend.toml
KEYS_PATH=/etc/futu-opend/keys.json

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Missing futu-opend config: $CONFIG_PATH" >&2
  exit 1
fi

if [ ! -f "$KEYS_PATH" ]; then
  echo "Missing API key file: $KEYS_PATH" >&2
  exit 1
fi

set -- /usr/local/bin/futu-opend --config "$CONFIG_PATH"

if [ -n "${FUTU_OPEND_DEVICE_ID:-}" ]; then
  set -- "$@" --device-id "$FUTU_OPEND_DEVICE_ID"
fi

exec "$@"
```

- [ ] **Step 3: Verify the shell script still parses**

Run: `sh -n script/entrypoint-opend.sh`
Expected: no output and exit code 0

### Task 2: Document Optional Runtime Env Var

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Find the existing local run and Compose usage sections**

Look for the sections that describe image build, `docker run`, and
`docker compose up -d` so the new env var is documented where users already
look for startup configuration.

- [ ] **Step 2: Add `docker run` example with `FUTU_OPEND_DEVICE_ID`**

Add an example like this near the existing runtime instructions:

```bash
docker run --rm \
  -e FUTU_OPEND_DEVICE_ID=your-stable-device-id \
  -v "$PWD/examples/futu-opend.toml:/etc/futu-opend/futu-opend.toml:ro" \
  -v "$PWD/examples/keys.json:/etc/futu-opend/keys.json:ro" \
  -p 11111:11111 \
  -p 22222:22222 \
  -p 33333:33333 \
  futu-opend-rs:local
```

Document that the env var is optional and only needed when the user wants a
fixed `--device-id`.

- [ ] **Step 3: Add Compose environment example**

Add a small example snippet or explanatory note showing:

```yaml
services:
  opend:
    environment:
      FUTU_OPEND_DEVICE_ID: your-stable-device-id
```

Make clear this is optional and not enabled by default in the sample stack.

### Task 3: Keep Sample Config Optional and Verify Docs

**Files:**

- Modify: `docker-compose.yaml` only if needed
- Verify: `README.md`
- Verify: `script/entrypoint-opend.sh`

- [ ] **Step 1: Decide whether `docker-compose.yaml` needs a commented example**

If the README snippet is sufficient, do not modify `docker-compose.yaml`.
If the repo style benefits from showing the env var inline, add only a
commented optional example under `services.opend`:

```yaml
    # environment:
    #   FUTU_OPEND_DEVICE_ID: your-stable-device-id
```

- [ ] **Step 2: Verify the entrypoint references the correct env var**

Run:
`grep -RInE "FUTU_OPEND_DEVICE_ID|device-id|keys\.json"
script/entrypoint-opend.sh README.md docker-compose.yaml`
Expected: matches only for the dedicated env var, the `--device-id`
documentation, and the existing `keys.json` references

- [ ] **Step 3: Verify markdown formatting and shell syntax**

Run:
`sh -n script/entrypoint-opend.sh && npx --yes markdownlint-cli
README.md docs/superpowers/specs/2026-04-23-opend-device-id-env-design.md
docs/superpowers/plans/2026-04-23-opend-device-id-env.md`
Expected: no shell syntax errors; markdownlint passes for touched docs

- [ ] **Step 4: Review final working tree**

Run:
`git diff -- script/entrypoint-opend.sh README.md docker-compose.yaml
docs/superpowers/specs/2026-04-23-opend-device-id-env-design.md
docs/superpowers/plans/2026-04-23-opend-device-id-env.md`
Expected: only the approved entrypoint and documentation changes appear
