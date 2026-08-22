#!/bin/sh
set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
IMAGE_DIR="$ROOT_DIR/images"
CONFIG_DIR="$ROOT_DIR/configs"
BUILD_DIR="$ROOT_DIR/buildroot/output/build"

UBOOT_OUTPUT_DIR="$ROOT_DIR/uboot"
UBOOT_TOOLS="$ROOT_DIR/uboot/tools"
UBOOT_OUTPUTS="
	download.bin
	idblock.img
	uboot.img
"

KERNEL_OUTPUT_DIR="$ROOT_DIR/kernel/arch/arm/boot"
KERNEL_OUTPUTS="
	zImage
"

BR2_OUTPUT_DIR="$ROOT_DIR/buildroot/output/images"
BR2_OUTPUTS="
	rootfs.ext4
	rootfs.tar
"

# Create an output directory
mkdir -p $IMAGE_DIR

# Copy uboot outputs
echo "Coppying uboot outputs"
cd $UBOOT_OUTPUT_DIR
cp $UBOOT_OUTPUTS $IMAGE_DIR

# Copy kernel outputs
echo "Coppying kernel outputs"
cd $KERNEL_OUTPUT_DIR
cp $KERNEL_OUTPUTS $IMAGE_DIR

# Copy buildroot outputs
echo "Coppying buildroot outputs"
cd $BR2_OUTPUT_DIR
cp $BR2_OUTPUTS $IMAGE_DIR

# Create env image
echo "Creating env image"
"$UBOOT_TOOLS/mkenvimage" -s 0x8000 -p 0x0 -o "$IMAGE_DIR/env.img" "$CONFIG_DIR/image-env.txt"
