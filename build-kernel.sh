#!/bin/bash

# You can use zyc clang 14 if u're unsure what toolchain to use. https://github.com/ncatt/clang
# Goodluck building!
# Ubuntu 25.10 error fix: sudo ln -s /lib/x86_64-linux-gnu/libxml2.so.16 /lib/x86_64-linux-gnu/libxml2.so.2
# Edit the zyc-clang directory name accordingly to ur toolchain
# Please remove "-Wno-error", "-Wno-int-conversion" and "-Wno-imcompatible-pointer-types" if you build this source with Clang version 13.
export TC=$HOME/zyc-clang
export PATH="$HOME/zyc-clang/bin:$PATH"

export CROSS_COMPILE=$TC/bin/aarch64-linux-gnu-
export LD=$TC/bin/ld.lld
export OBJCOPY=$TC/bin/llvm-objcopy
export AS=$TC/bin/llvm-as
export NM=$TC/bin/llvm-nm
export STRIP=$TC/bin/llvm-strip
export OBJDUMP=$TC/bin/llvm-objdump
export READELF=$TC/bin/llvm-readelf
export CC=$TC/bin/clang
export CROSS_COMPILE_ARM32=$TC/bin/arm-linux-gnueabi-
export ARCH=arm64
export ANDROID_MAJOR_VERSION=r

export KCFLAGS=' -w -pipe -O3 -Wno-int-conversion'
export KCPPFLAGS=' -O3'
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

rm -rf out/
make -C $(pwd) O=$(pwd)/out clean -j$(nproc) && make -C $(pwd) O=$(pwd)/out mrproper -j$(nproc)
clear
 
echo "thanks for build nightly kernel."
echo "made by @ncatt and all contributors in Samsung-MT6768-Devs"
echo "version: monochrome_r1"

make -C $(pwd) O=$(pwd)/out -j$(nproc) a32_mono_defconfig
make -s -C $(pwd) O=$(pwd)/out -j$(nproc)
echo "build done?"
