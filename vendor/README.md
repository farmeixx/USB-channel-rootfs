Self-contained vendor payload for rootfs builds: kernel modules, device
firmware and kernel metadata in one place, so a build needs nothing
external (no CI checkpoints, no firmware clone).

- kernel-modules-7.3.0-rc7-mainline.tar.zst - module set
- firmware.tar.zst - device firmware (extracts to lib/firmware)
- kernel-release.txt - 7.3.0-rc7-mainline
- kernel.config / System.map - kernel metadata of the matching build
- SHA256SUMS - checksums

Source: validated alpine-20261031062555 rootfs.

Boot materials (from the validated alpine-20261031062555 boot.img):

- Image.gz - the validated mainline kernel image
- sdm632-motorola-channel.dtb - the validated device tree blob
- mkbootimg.py - pre-GKI single-file packer; pack with the KERNEL_BOOT_*
  values from conf and any cmdline (userdata or sdcard)
