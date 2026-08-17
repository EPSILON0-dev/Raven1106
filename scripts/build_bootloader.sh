#!/bin/sh
set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
BUILD_DIR="$ROOT_DIR/buildroot/output/build"

TOOLCHAIN_PREFIX="$ROOT_DIR/buildroot/output/host/bin/arm-buildroot-linux-gnueabihf-"

RKBIN_REPO="https://github.com/rockchip-linux/rkbin"
UBOOT_BRANCH="next-dev"

IMAGE_DIR="$ROOT_DIR/buildroot/output/images"
IMAGES="rv1106_idblock_v1.15.102.img uboot.img"

# Clone the repo if not already cloned
cd $BUILD_DIR
if [ ! -d rkbin ]; then
	git clone $RKBIN_REPO
else
	echo "rkbin repo already cloned."
fi

# Build the uboot images
echo "Building uboot images"
cd $BUILD_DIR/uboot-$UBOOT_BRANCH
./make.sh CROSS_COMPILE=$TOOLCHAIN_PREFIX

# Copy the images to the output image dir
echo "Copying images: $IMAGES"
cp $IMAGES $IMAGE_DIR

