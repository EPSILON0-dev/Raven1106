default: image

CONFIG_DIR                 := $(shell pwd)/configs
IMAGE_DIR                  := $(shell pwd)/images

BUILDROOT_DIR              := $(shell pwd)/buildroot
BUILDROOT_CONFIG           := $(shell pwd)/configs/buildroot-config
BUILDROOT_HOST_BINARIES    := $(shell pwd)/buildroot/output/host/bin
BUILDROOT_TOOLCHAIN_PREFIX := $(BUILDROOT_DIR)/output/host/bin/arm-buildroot-linux-musleabihf-

CROSSTOOL_DIR              := $(shell pwd)/crosstool-ng

LEGACY_TOOLCHAIN_DIR       := $(shell pwd)/legacy-toolchain
LEGACY_TOOLCHAIN_PREFIX    := $(LEGACY_TOOLCHAIN_DIR)/bin/arm-unknown-linux-uclibcgnueabihf-

KERNEL_DIR                 := $(shell pwd)/kernel
KERNEL_CONFIG              := $(shell pwd)/configs/kernel-config

UBOOT_DIR                  := $(shell pwd)/uboot
UBOOT_CONFIG			   := $(shell pwd)/configs/uboot-config 

######################################################################
# Legacy toolchain (used for Kernel and Uboot)
######################################################################

crosstool:
	$(CROSSTOOL_DIR)/bootstrap
	$(CROSSTOOL_DIR)/configure --enable-local
	cp $(CONFIG_DIR)/crosstool-config $(CROSSTOOL_DIR)/.config
	make -C $(CONFIG_DIR) -j

legacytoolchain: crosstool
	$(CROSSTOOL_DIR)/ct-ng build

legacytoolchain-config: crosstool
	cp $(CONFIG_DIR)/crosstool-config $(CROSSTOOL_DIR)/.config
	$(CROSSTOOL_DIR)/ct-ng menuconfig
	cp $(CROSSTOOL_DIR)/.config $(CONFIG_DIR)/crosstool-config

.PHONY: crosstool legacytoolchain legacytoolchain-config

######################################################################
# Uboot
######################################################################

uboot:
	cp $(UBOOT_CONFIG) $(UBOOT_DIR)/.config
#   make -C $(UBOOT_DIR) CROSS_COMPILE=$(LEGACY_TOOLCHAIN_PREFIX)
#   cd $(UBOOT_DIR) && ./make.sh --spl $(CONFIG_DIR)/spl-pack.ini CROSS_COMPILE=$(LEGACY_TOOLCHAIN_PREFIX)
	cd $(UBOOT_DIR) && ./make.sh $(CONFIG_DIR)/spl-pack.ini CROSS_COMPILE=$(LEGACY_TOOLCHAIN_PREFIX)

uboot-config:
	cp $(UBOOT_CONFIG) $(UBOOT_DIR)/.config
	make -C $(UBOOT_DIR) menuconfig
	cp $(UBOOT_DIR)/.config $(UBOOT_CONFIG)

uboot-clean:
	make -C $(UBOOT_DIR) clean

.PHONY: uboot uboot-config uboot-clean

######################################################################
# Kernel
######################################################################

KERNEL_BUILD_OPTS := \
	CROSS_COMPILE=$(LEGACY_TOOLCHAIN_PREFIX) \
	CC=$(LEGACY_TOOLCHAIN_PREFIX)gcc \
	ARCH=arm

kernel:
	cp $(CONFIG_DIR)/kernel-config $(KERNEL_DIR)/.config
	make -C $(KERNEL_DIR) $(KERNEL_BUILD_OPTS) -j`nproc`

kernel-config:
	cp $(CONFIG_DIR)/kernel-config $(KERNEL_DIR)/.config
	make -C $(KERNEL_DIR) $(KERNEL_BUILD_OPTS) menuconfig
	cp $(KERNEL_DIR)/.config $(CONFIG_DIR)/kernel-config

kernel-clean:
	make -C $(KERNEL_DIR) clean

.PHONY: kernel kernel-config kernel-clean

######################################################################
# Device tree
######################################################################

dtb:
	cpp -nostdinc \
		-I "$(KERNEL_DIR)/arch/arm/boot/dts" \
		-I "$(KERNEL_DIR)/include" \
		-undef -x assembler-with-cpp \
		$(CONFIG_DIR)/device-tree.dts \
		$(IMAGE_DIR)/device-tree.dts.pp
	dtc \
		-I dts \
		-O dtb \
		-o $(IMAGE_DIR)/device-tree.dtb \
		$(IMAGE_DIR)/device-tree.dts.pp

.PHONY: dtb

######################################################################
# Buildroot
######################################################################

buildroot:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) -j`nproc`

buildroot-config:
	make -C $(BUILDROOT_DIR) defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)
	make -C $(BUILDROOT_DIR) menuconfig
	make -C $(BUILDROOT_DIR) update-defconfig BR2_DEFCONFIG=$(BUILDROOT_CONFIG)

buildroot-clean:
	make -C $(BUILDROOT_DIR) clean

.PHONY: buildroot buildroot-config buildroot-clean

######################################################################
# Final Image
######################################################################

image: buildroot dtb uboot kernel
	./scripts/collect_images.sh
	./scripts/build_images.sh

######################################################################
# Docker
######################################################################

docker:
	./scripts/start_docker.sh
