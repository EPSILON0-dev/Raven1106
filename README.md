# raven1106-os

OS build for the Raven1106 custom SBC, based on Buildroot.

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
