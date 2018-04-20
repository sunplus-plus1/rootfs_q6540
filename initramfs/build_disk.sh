#!/bin/bash

# Toolchain
ARCH=arm
CROSS=../../../build/tools/armv5-eabi--glibc--stable/bin/armv5-glibc-linux-

function abspath() {
    # generate absolute path from relative path
    # $1     : relative filename
    # return : absolute path
    if [ -d "$1" ]; then
        # dir
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        # file
        if [[ $1 = /* ]]; then
            echo "$1"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    fi
}

# sub builds need absolute path
CROSS=`abspath ${CROSS}gcc`
echo $CROSS
${CROSS} -v 2>/dev/null
if [ $? -ne 0 ];then
	echo "Not found gcc : $CROSS"
	exit 1
fi
CROSS=${CROSS%gcc}

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
cd -
size $BBX/busybox
echo "Installed ($BBXCFG)"

echo "Extra copy..."
if [ -d extra/ ];then
	cp -av extra/* $DISKOUT
fi
