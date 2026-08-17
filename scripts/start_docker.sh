#!/bin/sh
set -eu

if ! docker image inspect rv1106-build > /dev/null 2> /dev/null; then
	echo "Building docker environment image"
	docker build -t rv1106-build .
else
	echo "Docker image already built"
fi

docker run --rm -it \
	-v "$(realpath $(dirname $0)/..):/work" \
	--user "$(id -u):$(id -g)" \
	rv1106-build
