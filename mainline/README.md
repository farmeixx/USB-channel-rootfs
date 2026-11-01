# mainline

Packs the boot image from the vendored kernel - no compilation, no
network. The kernel and DTB ship in ../vendor (extracted from the
validated alpine-20261031062555 boot.img).

Run: bash mainline/pack.sh
Result: mainline/out/boot-channel.img (cmdline from conf/mainline.conf,
SD-card root: PARTLABEL=sdcard).
