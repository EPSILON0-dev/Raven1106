#!/bin/sh
set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
BUILD_DIR="$ROOT_DIR/buildroot/output/build"

TOOLCHAIN_PREFIX="$ROOT_DIR/buildroot/output/host/bin/arm-buildroot-linux-musleabihf-"

RKBIN_REPO="https://github.com/rockchip-linux/rkbin"
UBOOT_BRANCH="next-dev"

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

