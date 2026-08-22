#!/bin/sh
set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
IMAGE_DIR="$ROOT_DIR/images"
CONFIG_DIR="$ROOT_DIR/configs"
BUILD_DIR="$ROOT_DIR/buildroot/output/build"

LINUX_BRANCH="develop-5.10"
LINUX_DIR="$BUILD_DIR/linux-$LINUX_BRANCH"

cpp -nostdinc \
	-I "$LINUX_DIR/arch/arm/boot/dts" \
	-I "$LINUX_DIR/include" \
	-undef -x assembler-with-cpp \
	$CONFIG_DIR/device-tree.dts \
	$IMAGE_DIR/device-tree.dts.pp

dtc \
	-I dts \
	-O dtb \
	-o $IMAGE_DIR/device-tree.dtb \
	$IMAGE_DIR/device-tree.dts.pp

