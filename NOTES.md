# Noted

## Boot commands (old)

fatload mmc 1:4 0x00008000 zImage
fatload mmc 1:4 0x00c00000 device-tree.dtb
setenv bootargs "console=ttyFIQ0,115200 blkdevparts=mmcblk1:0x8000@0x0(env),0x80000@0x8000(idblock),0x40000@0x88000(uboot),64M@4M(boot),-(rootfs) root=/dev/mmcblk1p5 rootfstype=ext4 rootwait earlycon"
bootz 0x00008000 - 0x00c00000

## Board design mistakes / problems

### USB Impedance

USB impedance miscalculation, MUX acts as a... MUX, not a retransmitter and adds an impedance of `10ohm`.

Fix:
* Swap `RN301` from 22ohm to 0ohm.
* Possibly swap `R301` and `R302` from 22ohm to 10ohm (not tested)

No board design modifications

### SD Card on wrong SDIO

The SD card is connected to `SDIO1` and RV1106 can only boot from `SDIO0`. Problem is unfixable without a major redesign.

Fix: Use the FSPI flash as a trampoline, populate `U202` and `C201`

Board design modifications: Change `U202` and `C201` from DNP to populated

### No pullups on FSPI Flash

Mask ROM reads the FSPI flash in a simple SPI mode, in that mode pin 7 (D3) acts as /HOLD and pin 3 (D2) acts as /WP. While not critical, some chips may not be read correctly.

No fix possible without board redesign

Board design modifications: Add 10kohm pullup resistors to pins 7 and 3 of `U202`

### Wrong ESP_BOOT pin exposed

ESP32C6 uses pin 9, not pin 8 as recovery boot

No fix possible without board redesign

Board design modifications: Move `R401` and `TP401` from pin 22 of `U402` to pin 23

### LED resistors too small

Status LEDs shine too bright with 1kohm resistors.

Fix: Swap `R3`, `R4` and `R5` with 10kohm resistors.

Board design modifications: Change `R3`, `R4` and `R5` values from 1kohm to 10kohm.
