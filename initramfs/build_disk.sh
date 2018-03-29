#!/bin/bash

# Toolchain
export PATH="../../../build/tools/armv5-eabi--glibc--stable/bin/:$PATH"
ARCH=arm
CROSS=armv5-glibc-linux-
#CROSS=armv7hf-glibc-linux-

# sub builds need absolute path
CROSS=`which ${CROSS%-gcc}`

# Output
DISKZ=disk-base-static.tgz
#DISKZ=disk-base-dynamic.tgz
DISKOUT=`pwd`/disk

# Busybox
BBX=busybox-1.24.1
BBXZ=../busybox/$BBX.tar.bz2
BBXCFG=configs/bbx_static_defconfig
#BBXCFG=configs/bbx_dynamic_defconfig

# Check sources
if [ ! -f $DISKZ ];then
	echo "Not found base: $DISKZ"
fi

if [ ! -f $BBXZ ];then
	echo "Not found busybox: $BBXZ"
	exit 1
fi

echo "Prepare disk base"
rm -rf $DISKOUT
tar xzf $DISKZ

echo "Prepare busybox"
rm -rf $BBX
tar xjf $BBXZ
cp -vf $BBXCFG $BBX/.config

echo "Build busybox"
echo make -C $BBX -j4 ARCH=$ARCH CROSS_COMPILE=$CROSS CONFIG_PREFIX=$DISKOUT install
make -C $BBX -j4 ARCH=$ARCH CROSS_COMPILE=$CROSS CONFIG_PREFIX=$DISKOUT all

echo "Install busybox"
cd $BBX && make -j4 ARCH=$ARCH CROSS_COMPILE=$CROSS CONFIG_PREFIX=$DISKOUT install
echo "Installed ($BBXCFG)"
