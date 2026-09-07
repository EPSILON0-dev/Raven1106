# Raven1106

Raspberry Pi like Single Board Computer based on the Rockchip RV1106.

**Board Image**

## Overview

## Hardware

## Operating System

## Demos

## Building

Enter the build environment (builds the Docker image on first run):
```sh
make docker
```

Inside the container, build everything (Buildroot + bootloader):
```sh
make
```

Then assemble a flashable SD card image (`buildroot/output/images/raven1106-sdcard.img`):
```sh
make image
```

Other targets: `make buildrootconfig`, `make ubootconfig`, `make kernelconfig` to edit and save the respective defconfigs in `configs/`.
