#!/bin/sh
set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
CONFIG_DIR="$ROOT_DIR/configs"
IMAGE_DIR="$ROOT_DIR/images"

BR2_HOST_BIN="$ROOT_DIR/buildroot/output/host/bin"

# Create a FAT image
echo "Creating FAT partition image"
cd $IMAGE_DIR
dd if=/dev/zero of=boot.vfat bs=1M count=64
mkfs.fat -F32 boot.vfat
echo "Coppying zImage"
mcopy -i boot.vfat zImage ::zImage
echo "Coppying Device Tree Binary"
mcopy -i boot.vfat device-tree.dtb ::device-tree.dtb

# Build the final image
echo "Generating Final Images"
echo "Generating SD Image"
"$BR2_HOST_BIN/genimage" \
	--rootpath "$(mktemp -d)" \
	--tmppath "$(mktemp -d)" \
	--inputpath "$IMAGE_DIR" \
	--outputpath "$IMAGE_DIR" \
	--config "$CONFIG_DIR/sdcard-image.cfg"

echo "Generating Flash Image"
"$BR2_HOST_BIN/genimage" \
	--rootpath "$(mktemp -d)" \
	--tmppath "$(mktemp -d)" \
	--inputpath "$IMAGE_DIR" \
	--outputpath "$IMAGE_DIR" \
	--config "$CONFIG_DIR/flash-image.cfg"
