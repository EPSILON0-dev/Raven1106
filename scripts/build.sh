#!/bin/sh

set -eu

# Directories and files
ROOT_DIR="$(realpath $(dirname $0)/..)"
IMAGE_DIR="$ROOT_DIR/images"
CONFIG_DIR="$ROOT_DIR/configs"
BUILD_DIR="$ROOT_DIR/buildroot/output/build"
BR2_OVERLAY_DIR="$ROOT_DIR/buildroot-overlayfs"
KERNEL_DIR="$ROOT_DIR/kernel"
MODULES_DIR="$BR2_OVERLAY_DIR/usr/ko"
DEBIAN_DIR="$ROOT_DIR/debian"
DEBIAN_ROOTFS_DIR="$DEBIAN_DIR/rootfs"
DEBIAN_OVERLAYFS_DIR="$ROOT_DIR/debian-overlayfs"
UBOOT_OUTPUT_DIR="$ROOT_DIR/uboot"
UBOOT_TOOLS="$ROOT_DIR/uboot/tools"
UBOOT_ARTIFACTS="download.bin idblock.img uboot.img"
KERNEL_OUTPUT_DIR="$ROOT_DIR/kernel/arch/arm/boot"
KERNEL_ARTIFACTS="zImage"
BR2_OUTPUT_DIR="$ROOT_DIR/buildroot/output/images"
BR2_ARTIFACTS="rootfs.ext4 rootfs.tar"
BR2_HOST_BIN="$ROOT_DIR/buildroot/output/host/bin"
ESP_HOSTED_DIR="$ROOT_DIR/esp-hosted"

# Debian configuration
DEBIAN_KERNEL_VERSION="5.10.252"
DEBIAN_USER="${BOARD_USER:-debian}"
DEBIAN_PASSWORD="${DEBIAN_PASSWORD:-raven}"
DEBIAN_SUITE="bookworm"  # Needs to match the one in the overlayfs 
DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"
DEBIAN_ROOTFS_SIZE="1G"
DEBIAN_PACKAGES_FILE="$CONFIG_DIR/debian-package-list.txt"

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

        debootstrap qemu-user-static binfmt-support
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

    docker run --rm -it --privileged \
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
        install -o 0 -g 0 -m 644 $module $MODULES_DIR
    done

    for module in $(find $ESP_HOSTED_DIR -name '*.ko'); do
        printout "Copying kernel module: $module"
        install -o 0 -g 0 -m 644 $module $MODULES_DIR
    done
}

setup_debootstrap_env()
{
    if ! mount | grep binfmt_misc > /dev/null 2> /dev/null; then
        printout "Mounting binfmt_misc"
        mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
	echo ':qemu-arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff:/usr/bin/qemu-arm-static:CF' > /proc/sys/fs/binfmt_misc/register || true
    else
        printout "Already mounted binfmt_misc"
    fi
}

build_debootstrap_rootfs()
{
    debian_packages=`sed ':a;N;$!ba;s/\n/,/g' $DEBIAN_PACKAGES_FILE`
    mkdir -p $DEBIAN_ROOTFS_DIR
    printout "Running debootstrap stage 1"
    printout "Installing packages: $debian_packages"
    debootstrap --arch="armhf" --foreign --variant=minbase \
        --include="$debian_packages" \
        "${DEBIAN_SUITE}" "${DEBIAN_ROOTFS_DIR}" "${DEBIAN_MIRROR}"
    printout "Running debootstrap stage 2"
    chroot $DEBIAN_ROOTFS_DIR /debootstrap/debootstrap --second-stage
}

debian_chroot_setup_script()
{
    printout "Setting up chroot environment"

    printout "chroot: Updating via apt-get"
    apt-get update
    apt-get upgrade -y --no-install-recommends openssh-server sudo

    printout "chroot: Adding user"
    useradd -m -s /bin/bash -G sudo "$DEBIAN_USER"
    echo "$DEBIAN_USER:$DEBIAN_PASSWORD" | chpasswd
    apt-get clean

    printout "Fixing debian overlayfs permissions"
    cat /manifest.txt | while read name user group perms; do
	chmod $perms "/$name"
	chown $user:$group "/$name"
    done

    rm /manifest.txt

    printout "chroot: Enabling ssh"
    systemctl enable ssh
    systemctl enable firstboot-resize.service
    systemctl enable setup-eth0-leds.service
}

copy_debian_overlayfs()
{
    printout "Copying debian overlayfs"
    cat $DEBIAN_OVERLAYFS_DIR/manifest.txt | while read name user group perms; do
    	mkdir -p `dirname "$DEBIAN_ROOTFS_DIR/$name"`
        cp -r "$DEBIAN_OVERLAYFS_DIR/$name" "$DEBIAN_ROOTFS_DIR/$name"
    done

    cp -r "$DEBIAN_OVERLAYFS_DIR/manifest.txt" "$DEBIAN_ROOTFS_DIR/manifest.txt"
}

copy_debian_modules()
{
    printout "Copying debian modules"
    module_dir="$DEBIAN_ROOTFS_DIR/lib/modules/$DEBIAN_KERNEL_VERSION"
    mkdir -p "$module_dir"

    for module in $(find $KERNEL_DIR -name '*.ko'); do
        printout "Copying kernel module: $module"
        install -o 0 -g 0 -m 644 $module $module_dir
    done

    for module in $(find $ESP_HOSTED_DIR -name '*.ko'); do
        printout "Copying kernel module: $module"
        install -o 0 -g 0 -m 644 $module $module_dir
    done
}

debian_chroot_setup()
{
    cp $ROOT_DIR/scripts/build.sh $DEBIAN_ROOTFS_DIR/tmp/build.sh
    chroot $DEBIAN_ROOTFS_DIR /tmp/build.sh debian-chroot-setup
    rm $DEBIAN_ROOTFS_DIR/tmp/build.sh
}

build_debian_rootfs_image()
{
   truncate -s $DEBIAN_ROOTFS_SIZE $DEBIAN_DIR/rootfs.ext4
   mkfs.ext4 -d $DEBIAN_DIR/rootfs/ $DEBIAN_DIR/rootfs.ext4 
   cp $DEBIAN_DIR/rootfs.ext4 $IMAGE_DIR
}

cleanup_debian_workdir()
{
   rm -rf $DEBIAN_DIR
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

build_debian_image()
{
    build_image_common
    setup_debootstrap_env
    build_debootstrap_rootfs
    copy_debian_overlayfs
    copy_debian_modules
    debian_chroot_setup
    build_debian_rootfs_image
    build_image
    cleanup_debian_workdir
}

case "$1" in
    setup) setup_docker_env ;;
    docker) start_docker_env ;;
    copy-modules) copy_kernel_modules ;;
    debian-chroot-setup) debian_chroot_setup_script ;;
    buildroot-image) build_br2_image ;;
    debian-image) build_debian_image ;;
    build-image) build_image ;;
    *) unknown_command ;;
esac
