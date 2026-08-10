#!/bin/bash

#u can use zyc clang 14 if u're unsure what toolchain to use. https://github.com/ZyCromerZ/Clang/releases/tag/14.0.6-20250704-release
# goodluck building sir
# gore ubuntu 25.10 error fix: sudo ln -s /lib/x86_64-linux-gnu/libxml2.so.16 /lib/x86_64-linux-gnu/libxml2.so.2
#edit the zyc clang directory name accordingly to ur toolchain.
export TC=${TC:-/home/vigus/zyc-clang}

export CROSS_COMPILE=$TC/bin/aarch64-linux-gnu-
export LD=$TC/bin/ld.lld
export OBJCOPY=$TC/bin/llvm-objcopy
export AS=$TC/bin/llvm-as
export NM=$TC/bin/llvm-nm
export STRIP=$TC/bin/llvm-strip
export OBJDUMP=$TC/bin/llvm-objdump
export READELF=$TC/bin/llvm-readelf
export CC=$TC/bin/clang
export ARCH=arm64

export KCFLAGS=' -w -pipe -O3'
export KCPPFLAGS=' -O3'
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

#setup configs directory
export CFGDIR=arch/arm64/configs

rm -rf $CFGDIR/compiled_defconfig
make -C $(pwd) O=$(pwd)/out clean -j$(nproc) && make -C $(pwd) O=$(pwd)/out mrproper -j$(nproc)
clear
 
if [ -z "$DEVICE_CHOICE" ]; then
  read -p "`echo -e 'nightly kernel builder \ntell what device you wanna build for \nsupported devices: a32, m22(experimental)  '`" choice
else
  choice=$DEVICE_CHOICE
fi

case "$choice" in 
  a32|A32 ) export DEVICE="a32";;
  m22|M22 ) export DEVICE="m22";;
  * ) echo "u made a typo or $choice not supported yet srry" && exit;;
esac

if [ -z "$PROFILE_CHOICE" ]; then
  read -p "`echo -e '\nselect tuning profile: \navailable: perf, balance, battery '`" prof_choice
else
  prof_choice=$PROFILE_CHOICE
fi

case "$prof_choice" in 
  perf ) export CFG_FRAG="perf.config";;
  balance ) export CFG_FRAG="balance.config";;
  battery ) export CFG_FRAG="battery.config";;
  * ) export CFG_FRAG="balance.config";;
esac

#add $CFGDIR/ksu.config at the end before ">" for ksu integration(optional)
cat $CFGDIR/a32_nightly_defconfig $CFGDIR/"$DEVICE".config $CFGDIR/$CFG_FRAG > $CFGDIR/compiled_defconfig

#selinux and gpu driver control
#buildable: mali bifrost r25p0, mali valhall r32p1, mali avalon r49p1[WIP]
echo '
# CONFIG_ALWAYS_ENFORCE is not set
CONFIG_ALWAYS_PERMISSIVE=y

CONFIG_MTK_GPU_VERSION="mali valhall r32p1"
' >> "$CFGDIR/compiled_defconfig"

make -C $(pwd) O=$(pwd)/out -j$(nproc) compiled_defconfig
make -s -C $(pwd) O=$(pwd)/out -j$(nproc)

IMAGECHECK="$(pwd)/out/arch/arm64/boot/Image"

if [ -f "$IMAGECHECK" ]; then
    echo "built nightly for device: $DEVICE"
    GPU_VER=$(sed -n 's/^CONFIG_MTK_GPU_VERSION="\([^"]*\)"/\1/p' \
        "$(pwd)/out/.config")

    if [ "$GPU_VER" != "mali bifrost r25p0" ]; then
        echo
        echo "================================================================"
        echo "warning: non-stock gpu driver selected"
        echo
        echo "built gpu driver : $GPU_VER"
        echo
        echo "Flash a custom vendor.img that has the corresponding Mali userspace libs,"
        echo "Flash a custom boot.img that has a modified DTS with the new driver support,"
        echo "or your device may bootloop"
        echo "================================================================"
        echo
    fi
fi

echo "$DEVICE"
