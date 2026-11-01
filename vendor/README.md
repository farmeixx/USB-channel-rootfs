Self-contained vendor payload for rootfs builds: kernel modules, device
firmware and kernel metadata in one place, so a build needs nothing
external (no CI checkpoints, no firmware clone).

- kernel-modules-7.3.0-rc7-mainline.tar.zst - module set
- firmware.tar.zst - device firmware (extracts to lib/firmware)
- kernel-release.txt - 7.3.0-rc7-mainline
- kernel.config / System.map - kernel metadata of the matching build
- SHA256SUMS - checksums

Source: validated alpine-20261031062555 rootfs.
