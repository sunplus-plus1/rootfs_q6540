#!/bin/bash

# arguments:
# $1 : v5 or v7 (default: v7)
# $2 : update (default: completely rebuild)

# default to v7 build

# Output
DISKZ=disk-base/
DISKOUT=`pwd`/disk
DISKLIB=${DISKOUT}/lib
DISKLIB64=${DISKOUT}/lib64

V7_BUILD=1
if [ "$1" = "v5" ]; then
	V7_BUILD=0
fi


function cp_q654_files() {
    cp -R ${DISKZ}lib/firmware/ ${DISKLIB}
#    if [ -d prebuilt/vip9000sdk ]; then
#        mkdir -p ${DISKOUT}/usr/include
#        cp prebuilt/vip9000sdk/drivers/* ${DISKLIB}
#        cp -R prebuilt/vip9000sdk/include/* ${DISKOUT}/usr/include
#    fi
    cp -av prebuilt/resize2fs/v8/* $DISKOUT
    check_remoteproc=`cat ${DISKOUT}/etc/profile | grep "REMOTEPROC"`
    if [ "${check_remoteproc}" == "" ]; then
        echo '
        # ADD REMOTEPROC
        if [ -d /sys/class/remoteproc/remoteproc0 ]; then
            if [ -f /lib/firmware/firmware ]; then
                echo "Boot CM4 firmware by remoteproc"
                echo firmware > /sys/class/remoteproc/remoteproc0/firmware
                echo start > /sys/class/remoteproc/remoteproc0/state
            fi
        fi' >> ${DISKOUT}/etc/profile
    fi
    # ADD modprobe parameter for VIP9000 NPU module "galcore" modprobe using
    FILE_GALCORE_ARG="${DISKOUT}/etc/modprobe.d/galcore.conf"
	mkdir -p ${DISKOUT}/etc/modprobe.d
    if [ -d ${DISKOUT}/etc/modprobe.d ]; then
        echo 'options galcore recovery=0 powerManagement=0 showArgs=1 irqLine=197 contiguousBase=0x78000000 contiguousSize=0x8000000' > ${FILE_GALCORE_ARG}

        # for VC8000 V4L2 vsi daemon
        cp -rf prebuilt/vsi/vsidaemon ${DISKOUT}/usr/bin
    fi
    mkdir -p ${DISKOUT}/etc/init.d
	cp ${DISKZ}etc/init.d/rc.resizefs ${DISKOUT}/etc/init.d/rc.resizefs
	if [ -d prebuilt/udev ]; then
		cp -av prebuilt/udev/* $DISKOUT
	fi
}

if [ "${ROOTFS_CONTENT}" = "BUILDROOT" ]; then
    
    if [ -f "${DISKLIB}/os-release" ]; then
        cp_q654_files
    fi
    exit 0

elif [ "${ROOTFS_CONTENT}" = "YOCTO" ]; then
	tar_rootfs=0

	if [ ! -d ${DISKOUT} ]; then
		tar_rootfs=1
	elif [ -f ${DISKOUT}/init ]; then
		rm -rf ${DISKOUT}
		tar_rootfs=1
	elif [ "$ARCH" = "arm64" ] && [ ! -f ${DISKLIB}/ld-linux-aarch64.so.1 ]; then
		rm -rf ${DISKOUT}
		tar_rootfs=1
	elif [ "$ARCH" != "arm64" ] && [ -f ${DISKLIB}/ld-linux-aarch64.so.1 ]; then
		rm -rf ${DISKLIB64}
		rm ${DISKLIB}/ld-linux-aarch64.so.1
		exit 0
	fi

	if [ ${tar_rootfs} -eq 1 ]; then
		tar jxvf rootfs.tar.bz2 &>/dev/null
		cp -R ${DISKZ}lib/firmware/ ${DISKLIB}
		if [ "$ARCH" = "arm64" ]; then
			if [ -d prebuilt/vip9000sdk ]; then
				cp prebuilt/vip9000sdk/drivers/* ${DISKLIB}
				cp -R prebuilt/vip9000sdk/include/* ${DISKOUT}/usr/include
			fi
		fi
	fi

	if [ "$ARCH" != "arm64" ]; then
		if [ -d ${DISKLIB64} ]; then
			rm -rf ${DISKLIB64}
			rm ${DISKLIB}/ld-linux-aarch64.so.1
		fi
		if [ $V7_BUILD -eq 1 ]; then
			if [ -d prebuilt/resize2fs/v7 ]; then
				cp -av prebuilt/resize2fs/v7/* $DISKOUT
			fi
		else
			if [ -d prebuilt/resize2fs/v5 ]; then
				cp -av prebuilt/resize2fs/v5/* $DISKOUT
			fi
		fi
	else
		cp -av prebuilt/resize2fs/v8/* $DISKOUT
		check_remoteproc=`cat ${DISKOUT}/etc/profile | grep "REMOTEPROC"`
		if [ "${check_remoteproc}" == "" ]; then
			echo '
			# ADD REMOTEPROC
			if [ -d /sys/class/remoteproc/remoteproc0 ]; then
				if [ -f /lib/firmware/firmware ]; then
					echo "Boot CM4 firmware by remoteproc"
					echo firmware > /sys/class/remoteproc/remoteproc0/firmware
					echo start > /sys/class/remoteproc/remoteproc0/state
				fi
			fi' >> ${DISKOUT}/etc/profile
		fi

		# ADD modprobe parameter for VIP9000 NPU module "galcore" modprobe using
		FILE_GALCORE_ARG="${DISKOUT}/etc/modprobe.d/galcore.conf"
		if [ -d ${DISKOUT}/etc/modprobe.d ]; then
			echo 'options galcore recovery=0 powerManagement=0 showArgs=1 irqLine=197 contiguousBase=0x78000000 contiguousSize=0x8000000' > ${FILE_GALCORE_ARG}

		# for VC8000 V4L2 vsi daemon
		cp -rf prebuilt/vsi/vsidaemon ${DISKOUT}/usr/bin
		fi
	fi
	cp ${DISKZ}etc/init.d/rc.resizefs ${DISKOUT}/etc/init.d/rc.resizefs
	if [ -d prebuilt/udev ]; then
		cp -av prebuilt/udev/* $DISKOUT
	fi
	exit 0
elif [ "${ROOTFS_CONTENT:0:6}" = "UBUNTU" ]; then
	if [ "$ARCH" != "arm64" ]; then
		exit 1
	fi

	if [ -f "${DISKOUT}/etc/lsb-release" ]; then
		DISTRIB_ID=$(grep '^DISTRIB_ID=' "${DISKOUT}/etc/lsb-release" | awk -F '=' '{print $2}')
		if [ "${DISTRIB_ID}" = "Ubuntu" ]; then
			exit 0
		fi
		rm -rf "${DISKOUT}"
	fi

	ROOTFS_CONTENT=${ROOTFS_CONTENT:7}
	rootfs_common_dir=$(realpath ubuntu/common)
	rootfs_src_dir=$(realpath ubuntu/${ROOTFS_CONTENT%%:*})
	rootfs_archive=$(echo -n "$ROOTFS_CONTENT" | awk -F ':' '{print $2}')
	if [ -z "${rootfs_archive}" ]; then
		suffix='.tar.gz'
		find_archive="find ${rootfs_src_dir}/ -name '*$suffix*' | head -n 1 | sed \"s/$suffix.*//\" | xargs basename"
		rootfs_name=$(eval "$find_archive")
		if [ -n "${rootfs_name}" ]; then
			rootfs_archive="${rootfs_name}${suffix}"
		else
			suffix=''
		fi
	else
		suffix=${rootfs_archive:0-7}
		rootfs_name=${rootfs_archive::-${#suffix}}
	fi
	if [ "$suffix" = ".tar.gz" ]; then
		tar_cmd='tar --strip-components 1 -xzf'
	else
		echo "Error: Unable to found rootfs archive files in ${rootfs_src_dir} folder"
		exit 1
	fi
	rootfs_attr_file=${rootfs_name}-attr.list
	if [ ! -f "${rootfs_src_dir}/${rootfs_attr_file}" ]; then
		echo "Error: Unable to found ${rootfs_attr_file} file in ${rootfs_src_dir} folder"
		exit 1
	fi

	mkdir -p "${DISKOUT}"
	echo "Uncompressing ${rootfs_archive}"
	if [ -x /usr/bin/pv ]; then
		pv -prb "${rootfs_src_dir}/${rootfs_archive}"* | $tar_cmd - -C "${DISKOUT}"
	else
		cat "${rootfs_src_dir}/${rootfs_archive}"* | $tar_cmd - -C "${DISKOUT}"
        fi
	if [ $? -ne 0 ]; then
		exit 1
	fi

	mkdir -p .tmp
	ln -srf "${rootfs_src_dir}/${rootfs_attr_file}" .tmp/attr.list

	cp -R "${DISKZ}lib/firmware/" "${DISKLIB}"
	if [ -d prebuilt/vip9000sdk ]; then
		cp prebuilt/vip9000sdk/drivers/* "${DISKLIB}"
		cp -R prebuilt/vip9000sdk/include/* "${DISKOUT}/usr/include"
	fi
	if [ -d prebuilt/udev ]; then
		cp -av prebuilt/udev/lib/udev/* "$DISKOUT/lib/udev"
	fi

	find ${rootfs_common_dir}/ -maxdepth 1 ! -name 'README.md' ! -path ${rootfs_common_dir}/ -exec cp -av {} "$DISKOUT" \;
	if [ -d "${rootfs_src_dir}/disk-private" ]; then
		cp -av "${rootfs_src_dir}/disk-private/"* "$DISKOUT"
	fi
	if [ -x "${rootfs_src_dir}/build_disk_private.sh" ]; then
		"${rootfs_src_dir}/build_disk_private.sh"
	fi
	exit 0
else
	if [ ! -f ${DISKOUT}/init ]; then
		rm -rf ${DISKOUT}
	fi
fi

UPDATE=0

if [ "$2" = "update" ]; then
	UPDATE=1
fi

# Toolchain
if [ "$ARCH" = "arm64" ]; then
	DISK_LIB="lib-v7hf lib-arm64"
elif [ $V7_BUILD -eq 1 ]; then
	DISK_LIB=lib-v7hf
else
	DISK_LIB=lib-v5
fi

if [ -z "${CROSS}" ]; then
	echo "CROSS=... is undefined"
	exit 1;
fi;

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
${CROSS} --version 2>/dev/null
if [ $? -ne 0 ]; then
	echo "Not found gcc : $CROSS"
	exit 1
fi
CROSS=${CROSS%gcc}

# Busybox
BBX=busybox-1.31.1
BBXZ=../busybox/$BBX.tar.xz
#BBXCFG=configs/bbx_static_defconfig
BBXCFG=configs/bbx_dynamic_defconfig

# Check sources
if [ ! -d $DISKZ ]; then
	echo "Not found base: $DISKZ"
fi

if [ ! -f $BBXZ ]; then
	echo "Not found busybox: $BBXZ"
	exit 1
fi

if [ ! -d $DISKOUT ]; then
	UPDATE=0
fi

if [ $UPDATE -eq 1 ]; then
	echo "Use current disk folder"
else
	echo "Prepare new disk base"
	rm -rf $DISKOUT
	cp -a $DISKZ $DISKOUT
	for d in ${DISK_LIB}; do cp -a $d/* $DISKOUT/; done
	cd $DISKOUT
	mkdir -p proc sys mnt tmp var run
	cd -

	echo "Build busybox with new config ($BBXCFG)"
	rm -rf $BBX
	tar xf $BBXZ
	cp -vf $BBXCFG $BBX/.config
fi

echo "Build busybox"
echo make -C $BBX -j4 ARCH=$ARCH CROSS_COMPILE=$CROSS CONFIG_PREFIX=$DISKOUT all
make -C $BBX -j ARCH=$ARCH CROSS_COMPILE=$CROSS CONFIG_PREFIX=$DISKOUT all

echo "Install busybox"
cd $BBX && make -j ARCH=$ARCH CROSS_COMPILE=$CROSS CONFIG_PREFIX=$DISKOUT install
cd -
size $BBX/busybox
echo "Installed ($BBXCFG)"

echo "Overwrite with extra/ ..."
if [ -d extra/ ]; then
	cp -av extra/* $DISKOUT
fi

if [ "$ARCH" = "arm64" ]; then
	if [ -d prebuilt/arm64 ]; then
		cp -av prebuilt/arm64/* $DISKOUT
		cp -av prebuilt/resize2fs/v8/* $DISKOUT
	fi
#	if [ -d prebuilt/vip9000sdk ]; then
#		cp prebuilt/vip9000sdk/drivers/* ${DISKLIB64}
#	fi
	# ADD modprobe parameter for VIP9000 NPU module "galcore" modprobe using
	FILE_GALCORE_ARG="${DISKOUT}/etc/modprobe.d/galcore.conf"
	if [ ! -d ${DISKOUT}/etc/modprobe.d ]; then
		mkdir -p ${DISKOUT}/etc/modprobe.d
	fi
	echo 'options galcore recovery=0 powerManagement=0 showArgs=1 irqLine=197 contiguousBase=0x78000000 contiguousSize=0x8000000' > ${FILE_GALCORE_ARG}
elif [ $V7_BUILD -eq 1 ]; then
	if [ -d prebuilt/resize2fs/v7 ]; then
		cp -av prebuilt/resize2fs/v7/* $DISKOUT
	fi
else
	if [ -d prebuilt/resize2fs/v5 ]; then
		cp -av prebuilt/resize2fs/v5/* $DISKOUT
	fi
fi
