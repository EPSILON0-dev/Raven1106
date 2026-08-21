default: image

CONFIGS := $(shell pwd)/configs

BUILDROOT_DIR    := buildroot
BUILDROOT_CONFIG := $(CONFIGS)/buildroot-config

build:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) -j`nproc`
	./scripts/build_bootloader.sh
	./scripts/build_dt.sh

image: build
	./scripts/collect_images.sh
	./scripts/build_images.sh

buildrootconfig:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) menuconfig
	make -C $(BUILDROOT_DIR) update-defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)

ubootconfig:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) uboot-menuconfig
	make -C $(BUILDROOT_DIR) uboot-update-defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)

linuxconfig:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) linux-menuconfig
	make -C $(BUILDROOT_DIR) linux-update-defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)

docker:
	./scripts/start_docker.sh
