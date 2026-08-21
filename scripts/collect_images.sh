#!/bin/sh
set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
IMAGE_DIR="$ROOT_DIR/images"
CONFIG_DIR="$ROOT_DIR/configs"
BUILD_DIR="$ROOT_DIR/buildroot/output/build"

UBOOT_BRANCH="next-dev"
UBOOT_TOOLS="$BUILD_DIR/uboot-$UBOOT_BRANCH/tools"

BR2_OUTPUT_DIR="$ROOT_DIR/buildroot/output/images"
BR2_OUTPUTS="rootfs.ext4 rootfs.tar rv1106_idblock_v1.15.102.img uboot.img zImage"

# Create an output directory
mkdir -p $IMAGE_DIR

# Copy buildroot outputs
echo "Coppying buildroot outputs"
cd $BR2_OUTPUT_DIR
cp $BR2_OUTPUTS $IMAGE_DIR

# Create env image
echo "Creating env image"
"$UBOOT_TOOLS/mkenvimage" -s 0x8000 -p 0x0 -o "$IMAGE_DIR/env.img" "$CONFIG_DIR/image-env.txt"
