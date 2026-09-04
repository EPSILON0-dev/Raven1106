#!/bin/sh

mount /dev/mmcblk1p4 /boot
dtc -I dtb -O dts -o dt.dts /boot/device-tree.dtb
vim dt.dts
dtc -I dts -O dtb dt.dts -o /boot/device-tree.dtb
