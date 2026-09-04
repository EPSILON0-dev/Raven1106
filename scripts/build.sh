#!/bin/sh

set -eu

ROOT_DIR="$(realpath $(dirname $0)/..)"
IMAGE_DIR="$ROOT_DIR/images"
CONFIG_DIR="$ROOT_DIR/configs"
BUILD_DIR="$ROOT_DIR/buildroot/output/build"
OVERLAY_DIR="$ROOT_DIR/overlay"
KERNEL_DIR="$ROOT_DIR/kernel"
MODULES_DIR="$OVERLAY_DIR/usr/ko"

UBUNTU_LINK="https://cloud-images.ubuntu.com/releases/server/jammy/release/ubuntu-22.04-server-cloudimg-armhf-root.tar.xz"

BR2_HOST_BIN="$ROOT_DIR/buildroot/output/host/bin"

UBOOT_OUTPUT_DIR="$ROOT_DIR/uboot"
UBOOT_TOOLS="$ROOT_DIR/uboot/tools"
UBOOT_ARTIFACTS="
	download.bin
	idblock.img
	uboot.img
"

KERNEL_OUTPUT_DIR="$ROOT_DIR/kernel/arch/arm/boot"
KERNEL_ARTIFACTS="
	zImage
"

BR2_OUTPUT_DIR="$ROOT_DIR/buildroot/output/images"
BR2_ARTIFACTS="
	rootfs.ext4
	rootfs.tar
"

printout()
{
    printf "\033[1m[build.sh]\033[0m "
    echo $@
}

printerr()
{
    printf "\033[1m[build.sh]\033[0m ERR "
    echo $@
}

setup_docker_env()
{
    PREREQUISITES="
        which sed make binutils build-essential diffutils gcc g++ bash patch gzip 
        bzip2 perl tar cpio unzip rsync file bc findutils wget git ncurses-dev curl 
        git python3 vim device-tree-compiler e2fsprogs fdisk u-boot-tools fakeroot 
        dosfstools mtools gperf bison flex texinfo help2man autoconf automake libtool  
        libtool-bin gawk xz-utils libstdc++6 meson ninja-build libzstd-dev 
        python-is-python3 libssl-dev
    "

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y $PREREQUISITES
    rm -rf /var/lib/apt/lists/*
}

start_docker_env()
{
    if ! docker image inspect rv1106-build > /dev/null 2> /dev/null; then
        printout "Building docker environment image"
        docker build -t rv1106-build .
    else
        printout "Docker image already built"
    fi

    docker run --rm -it \
        -v "$(realpath $(dirname $0)/..):/work" \
        --user "$(id -u):$(id -g)" \
        rv1106-build
}

unknown_command()
{
    printerr "Unknown command, exiting"
    exit 1
}

copy_uboot_out()
{
    printout "Copying uboot outputs"
    cd $UBOOT_OUTPUT_DIR
    cp $UBOOT_ARTIFACTS $IMAGE_DIR
}

copy_kernel_out()
{
    printout "Copying kernel outputs"
    cd $KERNEL_OUTPUT_DIR
    cp $KERNEL_ARTIFACTS $IMAGE_DIR
}

copy_buildroot_out()
{
    printout "Copying buildroot outputs"
    cd $BR2_OUTPUT_DIR
    cp $BR2_ARTIFACTS $IMAGE_DIR
}

copy_kernel_modules()
{
    mkdir -p $MODULES_DIR
    for module in $(find $KERNEL_DIR -name '*.ko'); do
        printout "Copying kernel module: $module"
        cp $module $MODULES_DIR
    done
}

create_env_image()
{
    printout "Creating env image"
    "$UBOOT_TOOLS/mkenvimage" -s 0x8000 -p 0x0 -o "$IMAGE_DIR/env.img" "$CONFIG_DIR/image-env.txt"
}

build_image()
{
    printout "Creating FAT partition image"
    cd $IMAGE_DIR
    dd if=/dev/zero of=boot.vfat bs=1M count=64
    mkfs.fat -F32 boot.vfat
    printout "Coppying zImage"
    mcopy -i boot.vfat zImage ::zImage
    printout "Coppying Device Tree Binary"
    mcopy -i boot.vfat device-tree.dtb ::device-tree.dtb

    # Build the final image
    printout "Generating Final Images"
    printout "Generating SD Image"
    "$BR2_HOST_BIN/genimage" \
        --rootpath "$(mktemp -d)" \
        --tmppath "$(mktemp -d)" \
        --inputpath "$IMAGE_DIR" \
        --outputpath "$IMAGE_DIR" \
        --config "$CONFIG_DIR/sdcard-image.cfg"
}

get_ubuntu_rootfs()
{
    if [ ! -f $ROOT_DIR/tmp/ubuntu-rootfs.tar.xz ]; then
        printout "Downloading ubuntu rootfs"
        curl "$UBUNTU_LINK" -o $ROOT_DIR/tmp/ubuntu-rootfs.tar.xz
    else
        printout "Ubuntu rootfs already downloaded"
    fi

    if [ ! -f $ROOT_DIR/tmp/rootfs.ext4 ]; then
        printout "Unpacking tarball to the rootfs partition"
        mkdir -p $ROOT_DIR/tmp/rootfs
        unxz -k $ROOT_DIR/tmp/ubuntu-rootfs.tar.xz
        tar xf $ROOT_DIR/tmp/ubuntu-rootfs.tar -C $ROOT_DIR/tmp/rootfs

        printout "Creating rootfs partition image"
        truncate -s 2G $ROOT_DIR/tmp/rootfs.ext4
        mkfs.ext4 -d $ROOT_DIR/tmp/rootfs $ROOT_DIR/tmp/rootfs.ext4
    else
        printout "Rootfs partition image already built"
    fi

    cp $ROOT_DIR/tmp/rootfs.ext4 $IMAGE_DIR/rootfs.ext4
}

build_image_common()
{
    copy_uboot_out
    copy_kernel_out
    create_env_image
}

build_br2_image()
{
    build_image_common
    copy_buildroot_out
    build_image
}

build_ubuntu_image()
{
    build_image_common
    get_ubuntu_rootfs
    build_image
}

case "$1" in
    setup) setup_docker_env ;;
    docker) start_docker_env ;;
    copy-modules) copy_kernel_modules ;;
    buildroot-image) build_br2_image ;;
    ubuntu-image) build_ubuntu_image ;;
    *) unknown_command ;;
esac