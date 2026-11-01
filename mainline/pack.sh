#!/usr/bin/env bash
# Pack the boot image from the vendored kernel: no compile, no network.
# Inputs:  vendor/Image.gz + vendor/sdm632-motorola-channel.dtb
# Output:  mainline/out/boot-channel.img (+ kernel-cmdline.txt)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
VENDOR="$ROOT/vendor"
source "$HERE/conf/mainline.conf"
OUT="$HERE/out"
mkdir -p "$OUT"
test -s "$VENDOR/Image.gz" || { echo "missing vendor/Image.gz" >&2; exit 1; }
test -s "$VENDOR/sdm632-motorola-channel.dtb" || { echo "missing vendor DTB" >&2; exit 1; }
test -s "$VENDOR/mkbootimg.py" || { echo "missing vendor/mkbootimg.py" >&2; exit 1; }
cat "$VENDOR/Image.gz" "$VENDOR/sdm632-motorola-channel.dtb" > "$OUT/Image.gz-dtb"
python3 "$VENDOR/mkbootimg.py" \
  --header_version "$KERNEL_BOOT_HEADER_VERSION" \
  --kernel "$OUT/Image.gz-dtb" \
  --cmdline "$KERNEL_CMDLINE" \
  --base "$KERNEL_BOOT_BASE" \
  --kernel_offset "$KERNEL_BOOT_KERNEL_OFFSET" \
  --ramdisk_offset "$KERNEL_BOOT_RAMDISK_OFFSET" \
  --second_offset "$KERNEL_BOOT_SECOND_OFFSET" \
  --tags_offset "$KERNEL_BOOT_TAGS_OFFSET" \
  --pagesize "$KERNEL_BOOT_PAGE_SIZE" \
  --output "$OUT/$KERNEL_BOOT_NAME"
test -s "$OUT/$KERNEL_BOOT_NAME"
printf '%s\n' "$KERNEL_CMDLINE" > "$OUT/kernel-cmdline.txt"
echo "packed: $OUT/$KERNEL_BOOT_NAME"
