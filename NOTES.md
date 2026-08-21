fatload mmc 1:4 0x00008000 zImage
fatload mmc 1:4 0x00c00000 rv1106g-evb1-v11.dtb
setenv bootargs "console=ttyFIQ0,115200 blkdevparts=mmcblk1:0x8000@0x0(env),0x80000@0x8000(idblock),0x40000@0x88000(uboot),64M@4M(boot),-(rootfs) root=/dev/mmcblk1p5 rootfstype=ext4 rootwait earlycon"
bootz 0x00008000 - 0x00c00000
