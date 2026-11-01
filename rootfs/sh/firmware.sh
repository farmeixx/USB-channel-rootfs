#!/usr/bin/env bash
# Vendor firmware installer: extracts the vendored firmware bundle into the
# target rootfs. Same CLI as the original installer (install <rootfs>); no
# clone, no network - the payload ships in ../vendor.
set -euo pipefail
if [ "${1:-}" != install ] || [ -z "${2:-}" ]; then
  echo "usage: firmware.sh install <rootfs>" >&2
  exit 2
fi
ROOTFS="$2"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test -s "$HERE/../vendor/firmware.tar.zst"
sudo tar --zstd -xf "$HERE/../vendor/firmware.tar.zst" -C "$ROOTFS/lib"
echo "firmware: vendored bundle installed to $ROOTFS/lib/firmware"
