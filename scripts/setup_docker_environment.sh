#!/bin/sh
set -eu

PREREQUISITES="
	which
	sed
	make
	binutils
	build-essential
	diffutils
	gcc
	g++
	bash
	patch
	gzip
	bzip2
	perl
	tar
	cpio
	unzip
	rsync
	file
	bc
	findutils
	wget
	git
	ncurses-dev
	curl
	git
	python3
	vim
	device-tree-compiler
	e2fsprogs
	fdisk
	u-boot-tools
	fakeroot
	dosfstools
	mtools
	gperf 
	bison 
	flex 
	texinfo 
	help2man    
	autoconf 
	automake 
	libtool 
	libtool-bin 
	gawk 
	xz-utils   
	libstdc++6  
	meson 
	ninja-build
	libzstd-dev
	python-is-python3
"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y $PREREQUISITES
rm -rf /var/lib/apt/lists/*
