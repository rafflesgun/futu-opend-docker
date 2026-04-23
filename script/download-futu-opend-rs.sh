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
  file=$(printf '%s' "$page" | grep -Eo "futu-opend-rs-[0-9]+\.[0-9]+\.[0-9]+-${rs_arch}\.tar\.gz" | head -n 1)
  if [ -z "$file" ]; then
    printf 'Unable to resolve latest %s tarball from download page\n' "$rs_arch" >&2
    exit 1
  fi
  resolved_ver=$(printf '%s' "$file" | sed -E "s/^futu-opend-rs-([0-9]+\.[0-9]+\.[0-9]+)-${rs_arch}\.tar\.gz$/\1/")
else
  resolved_ver=$requested_ver
fi

if [ -z "$resolved_ver" ]; then
  printf '%s\n' 'Unable to resolve requested FUTU_OPEND_RS_VER' >&2
  exit 1
fi

file=${file:-"futu-opend-rs-${resolved_ver}-${rs_arch}.tar.gz"}
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

if [ "$requested_ver" != "$resolved_ver" ]; then
  rm -rf "futu-opend-rs-${requested_ver}"
  ln -s "futu-opend-rs-${resolved_ver}" "futu-opend-rs-${requested_ver}"
fi
