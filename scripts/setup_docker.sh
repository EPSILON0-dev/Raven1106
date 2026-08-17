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
"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y $PREREQUISITES
rm -rf /var/lib/apt/lists/*
