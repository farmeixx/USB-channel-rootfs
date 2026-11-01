#!/usr/bin/env bash
# Rootfs builder (modules-included): one script, three distros. Fully
# self-contained: consumes ONLY the vendored payload in ../vendor - kernel
# modules, firmware, kernel metadata. No checkpoint, no CI, no clones.
# Produces a GPT SD-card disk image (PARTLABEL=sdcard from conf/rootfs.conf).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECTION="$ROOT/rootfs"
CACHE="$ROOT/cache"
BUILDS="$ROOT/build"
VENDOR="$ROOT/vendor"
export LC_ALL=C

DISTRO="${1:-}"
usage(){ cat <<EOF
Usage: bash rootfs/build.sh <alpine|debian|ubuntu>

Consumes the vendored payload in vendor/ and creates
build/rootfs/<distro>/<distro>-STAMP.img (GPT SD-card image).
Pack the boot image separately: bash mainline/pack.sh
EOF
}
case "$DISTRO" in alpine|debian|ubuntu) ;; *) usage; exit 2;; esac

source "$SECTION/conf/device.conf"
source "$SECTION/conf/rootfs.conf"

for shared in \
    etc/NetworkManager/conf.d/10-channel.conf \
    usr/local/sbin/channel-grow-rootfs \
    usr/local/sbin/channel-zram-swap \
    usr/local/libexec/channel-wait-alsa \
    usr/share/alsa/ucm2/conf.d/motorola-channe/motorola-channe.conf \
    usr/share/alsa/ucm2/conf.d/motorola-channe/pulseaudio.conf; do
  ref="$SECTION/distros/alpine/rootfs/$shared"
  for other in "$SECTION/distros/debian/rootfs" "$SECTION/distros/ubuntu/rootfs"; do
    if ! diff -q "$ref" "$other/$shared" >/dev/null 2>&1; then
      echo "ERROR: shared overlay drifted: $other/$shared differs from $ref" >&2
      exit 1
    fi
  done
done
: "${DEVICE:=channel}"
case "$DISTRO" in
  alpine) export IMAGE_FREE_MIN="${IMAGE_FREE_MIN_ALPINE:-32}";;
  *)      export IMAGE_FREE_MIN="${IMAGE_FREE_MIN_DEBIAN_UBUNTU:-64}";;
esac
export IMAGE_SIZE_MB="${IMAGE_SIZE_MB:-1024}"

say() { printf '\n[%s] %s\n' "$DEVICE" "$*"; }

KREL="$(cat "$VENDOR/kernel-release.txt")"
MODULES="$VENDOR/kernel-modules-$KREL.tar.zst"
test -s "$MODULES" || { echo "missing $MODULES" >&2; exit 1; }
test -s "$VENDOR/kernel.config" -a -s "$VENDOR/System.map" || { echo "missing vendor kernel metadata" >&2; exit 1; }

source "$SECTION/sh/deps.sh"
install_host_deps "$DISTRO"

OUT_DIR="$CACHE/rootfs/$DISTRO/out"
WORK_DIR="$CACHE/rootfs/$DISTRO/work"
BUILDER="$ROOT/.work/rootfs/$DISTRO/raw/.local-raw-build.sh"
mkdir -p "$OUT_DIR" "$WORK_DIR" "$(dirname "$BUILDER")" "$BUILDS/rootfs/$DISTRO"
rm -f "$OUT_DIR"/*
export ROOT_PARTITION_LABEL="${ROOT_PARTITION_LABEL:-sdcard}"
python3 "$SECTION/sh/lib/raw-rootfs-builder.py" "$SECTION/distros/$DISTRO/build.sh" "$BUILDER" "$DISTRO" "$DEVICE"

export DISTRO ROOTFS_LABEL="$DISTRO" KERNEL_RELEASE="$KREL" WORK_DIR OUT_DIR
export REPO_ROOT="$SECTION"
export KERNEL_MODULES_ARCHIVE="$MODULES"
export KERNEL_CONFIG_FILE="$VENDOR/kernel.config" KERNEL_SYSTEM_MAP_FILE="$VENDOR/System.map"
say "Building $DEVICE $DISTRO from the vendored kernel modules; no kernel compile."
bash "$BUILDER"

RAW="$OUT_DIR/$DISTRO-$DEVICE-rootfs.img"
STAMP="$(date -u +%Y%m%d%H%M%S)"
NAME="$DISTRO-$STAMP"
DEST="$BUILDS/rootfs/$DISTRO"
mv "$RAW" "$DEST/$NAME.img"
cp "$OUT_DIR/build-info.txt" "$DEST/$NAME.build-info.txt"
printf 'device=%s\ndistribution=%s\nbuild_utc=%s\nkernel_release=%s\nmodules_archive=%s\n' \
  "$DEVICE" "$DISTRO" "$STAMP" "$KREL" "vendor/kernel-modules-$KREL.tar.zst" > "$DEST/$NAME.local-build.txt"
if [ -s "$ROOT/mainline/out/boot-$DEVICE.img" ]; then
  cp "$ROOT/mainline/out/boot-$DEVICE.img" "$DEST/$NAME.boot.img"
  say "Matching boot image: $DEST/$NAME.boot.img"
else
  say "Boot image not packed yet: run bash mainline/pack.sh"
fi
(cd "$DEST" && sha256sum "$NAME.img" "$NAME.build-info.txt" "$NAME.local-build.txt" > "$NAME.SHA256SUMS")
say "Finished: $DEST/$NAME.img"
