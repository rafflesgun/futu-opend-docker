# Docker Latest Version Resolution Design

## Summary

Add one repo-local shell script that resolves the newest
`futu-opend-rs` version from the upstream download page and lets the
Docker build use that version when explicitly requested with
`--build-arg FUTU_OPEND_RS_VER=latest`. Plain `docker build .` remains
pinned to the Dockerfile default, while `latest` becomes an opt-in
escape hatch.

## Goals

- Keep plain `docker build .` reproducible with a pinned default version.
- Support opt-in automatic latest resolution through one build arg.
- Use the upstream download page as the source of truth for latest
  release discovery.
- Keep implementation minimal and isolated to Dockerfile plus one
  script.
- Fail early when version resolution, checksum, or tarball availability
  is invalid.

## Non-Goals

- Make every plain `docker build .` float to the newest upstream
  release.
- Auto-edit `Dockerfile` to bump `ARG FUTU_OPEND_RS_VER`.
- Add compose or CI wiring in this change.
- Introduce extra docs updates in this change.
- Replace the existing ability to pin an explicit version.

## Current State

`Dockerfile` currently pins:

```dockerfile
ARG FUTU_OPEND_RS_VER=1.4.70
```

Build stage download URL shape is:

```text
https://futuapi.com/releases/rs-v${FUTU_OPEND_RS_VER}/futu-opend-rs-${FUTU_OPEND_RS_VER}-${RS_ARCH}.tar.gz
```

Users can already override version manually through `docker build`
build args, but there is no supported value such as `latest` that
resolves the newest upstream release automatically.

## Proposed Design

### Script location

- Add `script/download-futu-opend-rs.sh`.

### Script behavior

Inputs:

- `TARGETARCH`
- `FUTU_OPEND_RS_VER`

Behavior:

1. If `FUTU_OPEND_RS_VER` is set to a concrete version such as
   `1.4.72`, use it directly.
1. If `FUTU_OPEND_RS_VER=latest`, fetch
   `https://www.futuapi.com/download/`.
1. Extract the first latest-version marker that matches
   `v<major>.<minor>.<patch>`.
1. Strip the `v` prefix and store the resolved version.
1. Map `TARGETARCH` to the upstream Linux release suffix:
   - `arm64` -> `linux-aarch64`
   - `amd64` -> `linux-x86_64`
1. Construct the tarball filename and release URL.
1. Download the tarball plus `.sha256` file.
1. Verify checksum before extraction.
1. Extract the archive into `/tmp` for the rest of the Docker build.

### Dockerfile behavior

Keep the existing pinned default:

```dockerfile
ARG FUTU_OPEND_RS_VER=1.4.70
```

Change the build stage so it calls the helper script instead of
hardcoding the `curl` download logic inline.

Build behavior becomes:

- `docker build .` -> uses pinned default `1.4.70`
- `docker build --build-arg FUTU_OPEND_RS_VER=1.4.72 .` -> uses explicit
  pinned override
- `docker build --build-arg FUTU_OPEND_RS_VER=latest .` -> resolves the
  newest upstream release from `/download/`

### Source of truth

Use `https://www.futuapi.com/download/` instead of the changelog page.
This page is better aligned with artifact discovery because it includes:

- an explicit latest-version section
- exact Linux tarball naming
- exact release path shape

### Output

Print concise progress lines during build:

- requested version input
- resolved version actually used
- resolved release URL
- checksum verification status

## Error Handling

- Download-page fetch failure: exit non-zero with actionable message.
- Version parse failure: exit non-zero with parse context hint.
- Unsupported `TARGETARCH`: exit non-zero with allowed values.
- Tarball or checksum download failure: exit non-zero before extraction.
- Checksum mismatch: exit non-zero.

## Testing and Verification

Verify with command-level checks:

- `sh -n script/download-futu-opend-rs.sh`
- `docker build --build-arg FUTU_OPEND_RS_VER=1.4.70 .`
- `docker build --build-arg FUTU_OPEND_RS_VER=latest .`

Optional real build verification (slow path):

- `docker build --platform linux/arm64 --build-arg FUTU_OPEND_RS_VER=latest .`
- `docker build --platform linux/amd64 --build-arg FUTU_OPEND_RS_VER=latest .`

## Scope

This design is intentionally small:

- one new shell script
- targeted Dockerfile build-stage modification
- no compose changes
- no documentation updates in this step
