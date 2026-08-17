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

Other targets: `make buildrootconfig`, `make ubootconfig`, `make kernelconfig` to edit and save the respective defconfigs in `configs/`.
