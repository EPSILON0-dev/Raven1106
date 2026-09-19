default: all

CONFIG_DIR          := $(shell pwd)/configs
IMAGE_DIR           := $(shell pwd)/images
CROSSTOOL_DIR       := $(shell pwd)/crosstool-ng
TOOLCHAIN_DIR       := $(shell pwd)/toolchain
TOOLCHAIN_PREFIX    := $(TOOLCHAIN_DIR)/bin/arm-unknown-linux-uclibcgnueabihf-
KERNEL_DIR          := $(shell pwd)/kernel
KERNEL_CONFIG       := $(shell pwd)/configs/kernel-config
UBOOT_DIR           := $(shell pwd)/uboot
UBOOT_CONFIG		:= $(shell pwd)/configs/uboot-config 
ESP_DRIVER_DIR		:= $(shell pwd)/esp-hosted/host

all: toolchain debian-image

######################################################################
# Toolchain (used for Kernel and Uboot)
######################################################################

crosstool:
	cd $(CROSSTOOL_DIR) && ./bootstrap
	cd $(CROSSTOOL_DIR) && ./configure --enable-local
	cp $(CONFIG_DIR)/crosstool-config $(CROSSTOOL_DIR)/.config
	make -C $(CROSSTOOL_DIR) -j

toolchain: crosstool
	cd $(CROSSTOOL_DIR) && ./ct-ng build

toolchain-config: crosstool
	cp $(CONFIG_DIR)/crosstool-config $(CROSSTOOL_DIR)/.config
	cd $(CROSSTOOL_DIR) && ./ct-ng menuconfig
	cp $(CROSSTOOL_DIR)/.config $(CONFIG_DIR)/crosstool-config

toolchain-clean: crosstool
	make -C $(CROSSTOOL_DIR) clean

.PHONY: crosstool toolchain toolchain-config toolchain-clean

######################################################################
# Uboot
######################################################################

uboot:
	cp $(UBOOT_CONFIG) $(UBOOT_DIR)/.config
	cd $(UBOOT_DIR) && ./make.sh $(CONFIG_DIR)/spl-pack.ini CROSS_COMPILE=$(TOOLCHAIN_PREFIX)

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
	CROSS_COMPILE=$(TOOLCHAIN_PREFIX) \
	CC=$(TOOLCHAIN_PREFIX)gcc \
	INSTALL_MOD_PATH=$(KERNEL_MODULES_DIR) \
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
		$(IMAGE_DIR)/device-tree.preprocessed.dts
	dtc \
		-I dts \
		-O dtb \
		-o $(IMAGE_DIR)/device-tree.dtb \
		$(IMAGE_DIR)/device-tree.preprocessed.dts
	dtc \
		-I dtb \
		-O dts \
		-o $(IMAGE_DIR)/device-tree.flattened.dts \
		$(IMAGE_DIR)/device-tree.dtb

.PHONY: dtb

######################################################################
# ESP32 SDIO driver
######################################################################

ESP_DRIVER_BUILD_OPTS := \
	CROSS_COMPILE=$(TOOLCHAIN_PREFIX) \
	KERNEL=$(KERNEL_DIR) \
	ARCH=arm \
	target=spi

espdriver:
	make -C $(ESP_DRIVER_DIR) $(ESP_DRIVER_BUILD_OPTS) -j`nproc`

.PHONY: espdriver

######################################################################
# Final Image
######################################################################

debian-image:
	@-mkdir images
	make kernel
	make dtb
	make uboot
	make espdriver
	./scripts/build.sh debian-image

.PHONY: debian-image

######################################################################
# Docker
######################################################################

docker:
	./scripts/build.sh docker

.PHONY: docker
