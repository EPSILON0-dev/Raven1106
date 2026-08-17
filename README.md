# Set of build scripts for the Operating System for the Raven1106 SBC

## Building

> Note that build is still W.I.P and there's no master build script


**Building the build environment container**
```sh
sudo docker build -t rv1106-build .
```

**Starting the build environment container**
```sh
sudo docker run --rm -it -v "$PWD:/work" --user "$(id -u):$(id -g)" rv1106-build
```

**Building the toolchain**
```sh
./toolchain/build.sh
```
