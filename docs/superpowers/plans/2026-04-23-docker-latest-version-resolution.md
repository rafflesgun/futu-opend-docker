# Docker Latest Version Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in Docker build path where `--build-arg FUTU_OPEND_RS_VER=latest` resolves the newest upstream FUTU-OpenD-rs release from `https://www.futuapi.com/download/`, while plain builds remain pinned.

**Architecture:** Move the release download logic out of the Dockerfile inline shell and into one focused helper script. The Docker build stage will call that script with `TARGETARCH` and `FUTU_OPEND_RS_VER`; the script will either use an explicit version directly or resolve `latest`, download the correct tarball plus checksum, verify it, and extract it into `/tmp` for the existing `COPY --from=build` steps.

**Tech Stack:** Dockerfile multi-stage build, POSIX `sh`, `curl`, `tar`, `sha256sum`, upstream FUTU download page parsing

---

## File Map

- Create: `script/download-futu-opend-rs.sh`
  Responsibility: resolve requested version, map architecture, download tarball and checksum, verify checksum, extract release under `/tmp`.
- Modify: `Dockerfile`
  Responsibility: copy the helper script into the build stage and replace the inline release download logic with one script invocation.

### Task 1: Add failing resolution checks for unsupported `latest` flow

**Files:**
- Create: `script/download-futu-opend-rs.sh`
- Modify: `Dockerfile`

- [ ] **Step 1: Write the initial script stub that fails for `latest`**

```sh
#!/bin/sh
set -eu

target_arch=${TARGETARCH:-}
requested_ver=${FUTU_OPEND_RS_VER:-}

if [ -z "$target_arch" ]; then
  printf '%s\n' 'TARGETARCH is required' >&2
  exit 1
fi

case "$target_arch" in
  arm64) rs_arch='linux-aarch64' ;;
  amd64) rs_arch='linux-x86_64' ;;
  *)
    printf 'Unsupported TARGETARCH: %s\n' "$target_arch" >&2
    exit 1
    ;;
esac

if [ "$requested_ver" = 'latest' ]; then
  printf '%s\n' 'latest resolution not implemented yet' >&2
  exit 1
fi

if [ -z "$requested_ver" ]; then
  printf '%s\n' 'FUTU_OPEND_RS_VER is required' >&2
  exit 1
fi

file="futu-opend-rs-${requested_ver}-${rs_arch}.tar.gz"
base_url="https://futuapi.com/releases/rs-v${requested_ver}"

curl -fL -o "$file" "$base_url/$file"
tar -xzf "$file"
```

- [ ] **Step 2: Run shell syntax check**

Run: `sh -n script/download-futu-opend-rs.sh`
Expected: no output, exit status 0

- [ ] **Step 3: Wire Dockerfile to call the helper so `latest` fails visibly**

Replace the build stage download block with:

```dockerfile
COPY --chmod=0755 script/download-futu-opend-rs.sh /usr/local/bin/download-futu-opend-rs.sh

RUN /usr/local/bin/download-futu-opend-rs.sh
```

and keep these existing build args before the `RUN`:

```dockerfile
ARG TARGETARCH
ARG FUTU_OPEND_RS_VER
```

- [ ] **Step 4: Run the intentional failing build for `latest`**

Run: `docker build --build-arg FUTU_OPEND_RS_VER=latest .`
Expected: FAIL with `latest resolution not implemented yet`

- [ ] **Step 5: Commit**

```bash
git add Dockerfile script/download-futu-opend-rs.sh
git commit -m "test: wire latest release downloader stub"
```

### Task 2: Implement latest-version resolution from `/download/`

**Files:**
- Modify: `script/download-futu-opend-rs.sh`

- [ ] **Step 1: Replace the stub with a failing parser-first test path**

Update the script so `latest` resolves through a dedicated parser block:

```sh
#!/bin/sh
set -eu

target_arch=${TARGETARCH:-}
requested_ver=${FUTU_OPEND_RS_VER:-}

if [ -z "$target_arch" ]; then
  printf '%s\n' 'TARGETARCH is required' >&2
  exit 1
fi

case "$target_arch" in
  arm64) rs_arch='linux-aarch64' ;;
  amd64) rs_arch='linux-x86_64' ;;
  *)
    printf 'Unsupported TARGETARCH: %s\n' "$target_arch" >&2
    exit 1
    ;;
esac

resolve_version() {
  if [ -z "$requested_ver" ]; then
    printf '%s\n' 'FUTU_OPEND_RS_VER is required' >&2
    exit 1
  fi

  if [ "$requested_ver" != 'latest' ]; then
    printf '%s\n' "$requested_ver"
    return 0
  fi

  page=$(curl -fsSL 'https://www.futuapi.com/download/')
  version=$(printf '%s' "$page" | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | tr -d 'v')

  if [ -z "$version" ]; then
    printf '%s\n' 'Unable to resolve latest version from download page' >&2
    exit 1
  fi

  printf '%s\n' "$version"
}

resolved_ver=$(resolve_version)
file="futu-opend-rs-${resolved_ver}-${rs_arch}.tar.gz"
base_url="https://futuapi.com/releases/rs-v${resolved_ver}"

printf 'Requested version: %s\n' "$requested_ver"
printf 'Resolved version: %s\n' "$resolved_ver"
printf 'Release URL: %s/%s\n' "$base_url" "$file"

curl -fL -o "$file" "$base_url/$file"
tar -xzf "$file"
```

- [ ] **Step 2: Run shell syntax check again**

Run: `sh -n script/download-futu-opend-rs.sh`
Expected: no output, exit status 0

- [ ] **Step 3: Run the build to verify `latest` now resolves instead of failing at the stub gate**

Run: `docker build --build-arg FUTU_OPEND_RS_VER=latest .`
Expected: build progresses past version resolution and download begins for the current latest release

- [ ] **Step 4: Tighten the parser to avoid false matches by anchoring on the explicit latest section**

Replace the `version=` assignment inside `resolve_version()` with:

```sh
  version=$(printf '%s' "$page" | grep -Eo '最新版本：v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^最新版本：v//')
```

If that proves brittle in practice, use this fallback chain instead:

```sh
  version=$(printf '%s' "$page" | grep -Eo '最新版本：v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^最新版本：v//')
  if [ -z "$version" ]; then
    version=$(printf '%s' "$page" | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | tr -d 'v')
  fi
```

- [ ] **Step 5: Commit**

```bash
git add script/download-futu-opend-rs.sh
git commit -m "feat: resolve latest futu-opend-rs version during build"
```

### Task 3: Add checksum verification and preserve pinned builds

**Files:**
- Modify: `script/download-futu-opend-rs.sh`
- Modify: `Dockerfile`

- [ ] **Step 1: Add checksum download and verification to the script**

Update the download block to:

```sh
checksum_file="${file}.sha256"

curl -fL -o "$file" "$base_url/$file"
curl -fL -o "$checksum_file" "$base_url/$checksum_file"

printf 'Verifying checksum: %s\n' "$checksum_file"
sha256sum -c "$checksum_file"

tar -xzf "$file"
```

- [ ] **Step 2: Ensure the build image has the checksum tool available**

Keep the build-stage package install including the Debian package set needed for:

```dockerfile
RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates curl tar && \
    rm -rf /var/lib/apt/lists/*
```

If `sha256sum` is missing in the active base image, extend it to:

```dockerfile
RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates coreutils curl tar && \
    rm -rf /var/lib/apt/lists/*
```
```

- [ ] **Step 3: Verify pinned-version builds still work unchanged**

Run: `docker build --build-arg FUTU_OPEND_RS_VER=1.4.70 .`
Expected: build succeeds using the explicit pinned version without hitting the latest-resolution parser

- [ ] **Step 4: Verify opt-in latest builds work on the active host arch**

Run: `docker build --build-arg FUTU_OPEND_RS_VER=latest .`
Expected: build succeeds, logs show requested version `latest`, resolved version from `/download/`, checksum verification success, and normal extraction

- [ ] **Step 5: Commit**

```bash
git add Dockerfile script/download-futu-opend-rs.sh
git commit -m "feat: verify futu-opend-rs downloads during docker build"
```

### Task 4: Final verification and cleanup

**Files:**
- Modify: `script/download-futu-opend-rs.sh`
- Modify: `Dockerfile`

- [ ] **Step 1: Simplify the final script to the minimal supported behavior**

Ensure the script ends in this shape:

```sh
#!/bin/sh
set -eu

target_arch=${TARGETARCH:-}
requested_ver=${FUTU_OPEND_RS_VER:-}

if [ -z "$target_arch" ]; then
  printf '%s\n' 'TARGETARCH is required' >&2
  exit 1
fi

if [ -z "$requested_ver" ]; then
  printf '%s\n' 'FUTU_OPEND_RS_VER is required' >&2
  exit 1
fi

case "$target_arch" in
  arm64) rs_arch='linux-aarch64' ;;
  amd64) rs_arch='linux-x86_64' ;;
  *)
    printf 'Unsupported TARGETARCH: %s\n' "$target_arch" >&2
    exit 1
    ;;
esac

if [ "$requested_ver" = 'latest' ]; then
  page=$(curl -fsSL 'https://www.futuapi.com/download/')
  resolved_ver=$(printf '%s' "$page" | grep -Eo '最新版本：v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^最新版本：v//')
  if [ -z "$resolved_ver" ]; then
    resolved_ver=$(printf '%s' "$page" | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | tr -d 'v')
  fi
else
  resolved_ver=$requested_ver
fi

if [ -z "$resolved_ver" ]; then
  printf '%s\n' 'Unable to resolve requested FUTU_OPEND_RS_VER' >&2
  exit 1
fi

file="futu-opend-rs-${resolved_ver}-${rs_arch}.tar.gz"
base_url="https://futuapi.com/releases/rs-v${resolved_ver}"
checksum_file="${file}.sha256"

printf 'Requested version: %s\n' "$requested_ver"
printf 'Resolved version: %s\n' "$resolved_ver"
printf 'Release URL: %s/%s\n' "$base_url" "$file"

curl -fL -o "$file" "$base_url/$file"
curl -fL -o "$checksum_file" "$base_url/$checksum_file"

printf 'Verifying checksum: %s\n' "$checksum_file"
sha256sum -c "$checksum_file"

tar -xzf "$file"
```

- [ ] **Step 2: Run final verification commands**

Run: `sh -n script/download-futu-opend-rs.sh`
Expected: no output, exit status 0

Run: `docker build --build-arg FUTU_OPEND_RS_VER=1.4.70 .`
Expected: PASS

Run: `docker build --build-arg FUTU_OPEND_RS_VER=latest .`
Expected: PASS

- [ ] **Step 3: Inspect Dockerfile for the final build-stage flow**

The build stage should now include this sequence:

```dockerfile
ARG TARGETARCH
ARG FUTU_OPEND_RS_VER

RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates curl tar && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

COPY --chmod=0755 script/download-futu-opend-rs.sh /usr/local/bin/download-futu-opend-rs.sh

RUN /usr/local/bin/download-futu-opend-rs.sh
```

- [ ] **Step 4: Commit**

```bash
git add Dockerfile script/download-futu-opend-rs.sh
git commit -m "feat: support opt-in latest futu-opend-rs docker builds"
```
