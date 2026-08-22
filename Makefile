default: image

BUILDROOT_DIR            := $(shell pwd)/buildroot
BUILDROOT_CONFIG         := $(shell pwd)/configs/buildroot-config
BUILDROOT_HOST_BINARIES  := $(shell pwd)/buildroot/output/host/bin

buildroot:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) -j`nproc`

buildroot-config:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) menuconfig
	make -C $(BUILDROOT_DIR) update-defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)

devicetree:
	./scripts/build_dt.sh

uboot:
	./scripts/build_bootloader.sh

kernel:
	# ./scripts/build_kernel.sh 
	# TODO

image: buildroot devicetree uboot kernel
	./scripts/collect_images.sh
	./scripts/build_images.sh


ubootconfig:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) uboot-menuconfig
	make -C $(BUILDROOT_DIR) uboot-update-defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)

linuxconfig:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(KERNEL_DIR) CROSS_COMPILE=$(BUILDROOT_HOST_BINARIES)/arm-buildroot-linux-gnueabihf- CC=$(BUILDROOT_HOST_BINARIES)/arm-buildroot-linux-gnueabihf-gcc ARCH=arm menuconfig
	make -C $(BUILDROOT_DIR) linux-update-defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)

docker:
	./scripts/start_docker.sh
