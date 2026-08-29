#!/bin/sh
set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
OVERLAY_DIR="$ROOT_DIR/overlay"
KERNEL_DIR="$ROOT_DIR/kernel"
MODULES_DIR="$OVERLAY_DIR/usr/ko"

mkdir -p $MODULES_DIR
for module in $(find $KERNEL_DIR -name '*.ko'); do
	echo "Copying kernel module: $module"
	cp $module $MODULES_DIR
done
