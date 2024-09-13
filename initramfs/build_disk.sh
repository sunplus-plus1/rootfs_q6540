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

partition=

LIBPATH=/usr/lib

if [ "${ROOTFS_CONTENT:0:5}" = "YOCTO" ]; then
	LIBPATH=/lib
fi

function replace_sbin_init() {
	if [ -f ${DISKOUT}/sbin/init ]; then
		rm -f ${DISKOUT}/sbin/init
	fi
	if [ "${OVERLAYFS}" = "1" ]; then
		mkdir -p ${DISKOUT}/overlay
cat <<EOF > ${DISKOUT}/sbin/init
#!/bin/sh
mount -t ext4 /dev/mmcblk0p${partition} /overlay
mkdir -p /overlay/upper
mkdir -p /overlay/work
mkdir -p /overlay/lower
mount -t overlay overlay -o lowerdir=/,upperdir=/overlay/upper,workdir=/overlay/work /mnt
mkdir -p /mnt/rom
pivot_root /mnt /mnt/rom
exec chroot . $1
EOF
chmod 0544 ${DISKOUT}/sbin/init
	else
		if [ "${ROOTFS_CONTENT}" = "BUSYBOX" ]; then
			cd ${DISKOUT}/sbin
				ln -s /bin/busybox init
			cd -
		else
			cd ${DISKOUT}/sbin
				ln -s $1 init
			cd -
		fi
	fi
}

function resize_partition() {

	if [ "${ROOTFS_CONTENT:0:6}" = "UBUNTU" ]; then
		
		cp buildroot/systemd/usr/bin/init_tasks.sh ${DISKOUT}/usr/bin/
		cp buildroot/systemd/usr/bin/resize_partition.sh ${DISKOUT}/usr/bin/
		cp buildroot/systemd/usr/lib/systemd/system/resize_partition.service ${DISKOUT}/usr/lib/systemd/system

		cd ${DISKOUT}/etc/systemd/system/multi-user.target.wants
		ln -s /usr/lib/systemd/system/resize_partition.service resize_partition.service
		cd -

	else

		cp buildroot/systemd/usr/bin/*  ${DISKOUT}/usr/bin/
		cp -R buildroot/systemd/usr/lib/systemd ${DISKOUT}${LIBPATH}
		
		cd ${DISKOUT}/etc/systemd/system/multi-user.target.wants
		ln -s ${LIBPATH}/systemd/system/resize_partition.service resize_partition.service
		ln -s ${LIBPATH}/systemd/system/init_tasks.service init_tasks.service
		cd -
		
	fi

	# This file is for resize_partition.service use
cat <<EOF > ${DISKOUT}/etc/systemd/resize-partition
DEVTYPE=$boot_from
DEVPART=$partition
EOF

}

function cp_files() {
	
    cp -R ${DISKZ}lib/firmware/ ${DISKLIB}

	# for overlayfs
	replace_sbin_init "/lib/systemd/systemd"
	
	# resize emmc/sdcard partition
	resize_partition

    # ADD modprobe parameter for VIP9000 NPU module "galcore" modprobe using
    FILE_GALCORE_ARG="${DISKOUT}/etc/modprobe.d/galcore.conf"
	if [ ! -d ${DISKOUT}/etc/modprobe.d ]; then
		mkdir -p ${DISKOUT}/etc/modprobe.d
	fi
    echo 'options galcore recovery=0 powerManagement=0 showArgs=1 irqLine=197 contiguousBase=0x78000000 contiguousSize=0x8000000' > ${FILE_GALCORE_ARG}

    # for VC8000 V4L2 vsi daemon
    cp -rf prebuilt/vsi/vsidaemon ${DISKOUT}/usr/bin

    # suspend
    cp ${DISKZ}etc/rc.suspend ${DISKOUT}/etc/rc.suspend
    cp ${DISKZ}etc/udev/rules.d/99-custom-suspend.rules ${DISKOUT}/etc/udev/rules.d/99-custom-suspend.rules

	if [ -d prebuilt/udev ]; then
		cp -av prebuilt/udev/lib/* $DISKOUT/lib
	fi

	sed -i '/\/agetty/ s|\/agetty|& -a root|' ${DISKOUT}${LIBPATH}/systemd/system/serial-getty@.service 	
}

if [ "$boot_from" = "EMMC" ]; then
	partition=8
	if [ "${OVERLAYFS}" = "1" ]; then
		partition=9
	fi
elif [ "$boot_from" = "SDCARD" ]; then
	partition=2
fi

# restore rootfs to factory setting
if [ "${OVERLAYFS}" = "1" ]; then

cat <<EOF > ${DISKOUT}/sbin/restore
#!/bin/sh
which systemctl
if [ "$$?" == "0" ]; then
	systemctl stop systemd-journald.service
	systemctl stop systemd-journald.socket
	journalctl --rotate
	journalctl --vacuum-time=1s
	systemctl stop systemd-journald.service
	systemctl stop systemd-journald.socket
	systemctl stop systemd-journald-audit.socket
	systemctl stop systemd-journald-dev-log.socket
fi
mount -t ext4 /dev/mmcblk0p$partition /mnt
rm -rf /mnt/lowwer/*
rm -rf /mnt/upper/*
rm -rf /mnt/work/*
reboot
EOF
	chmod 0544 ${DISKOUT}/sbin/restore
	if [ "${ROOTFS_CONTENT}" != "BUSYBOX" ]; then
		cp buildroot/systemd/usr/lib/systemd/system/monitor_keys.service ${DISKOUT}${LIBPATH}/systemd/system/
		if [ -d "${DISKOUT}/etc/systemd/system/multi-user.target.wants" ]; then
			cd ${DISKOUT}/etc/systemd/system/multi-user.target.wants
			ln -s ${LIBPATH}/systemd/system/monitor_keys.service monitor_keys.service
			cd -
		fi
	fi
fi

if [ "${ROOTFS_CONTENT}" = "BUILDROOT" ]; then
    
    if [ -f "${DISKLIB}/os-release" ]; then
		# Remove default config of getty@.service.d
		if [ -d "${DISKOUT}/usr/lib/systemd/system/getty@.service.d" ]; then
			rm -rf "${DISKOUT}/usr/lib/systemd/system/getty@.service.d"
		fi

		# Add virtual console tty1~3
		mkdir -p ${DISKOUT}/etc/systemd/system/getty.target.wants
		cd ${DISKOUT}/etc/systemd/system/getty.target.wants
		ln -s /usr/lib/systemd/system/getty@.service getty@tty1.service
		ln -s /usr/lib/systemd/system/getty@.service getty@tty2.service
		ln -s /usr/lib/systemd/system/getty@.service getty@tty3.service
		cd -
		cp_files
    fi
	exit 0

elif [ "${ROOTFS_CONTENT}" = "BUSYBOX" ]; then
    #suspend/resume disable wlan0.
    if [ -d ${DISKOUT} ]; then
        if [ ! -f "${DISKOUT}/bin/suspend_closewifi" ]; then
            cp -rf prebuilt/suspend/suspend_closewifi ${DISKOUT}/bin
            sed -i '/\/bin\/echo "End of \$0"/ { x; s|^|/bin/suspend_closewifi \&\n|; G}' ${DISKOUT}/etc/init.d/rcS
        fi
    fi	

elif [ "${ROOTFS_CONTENT:0:5}" = "YOCTO" ]; then
    if [ -f "${DISKOUT}/usr/lib/os-release" ]; then
		cp_files
	fi
	exit 0

elif [ "${ROOTFS_CONTENT:0:6}" = "UBUNTU" ]; then
	if [ "$ARCH" != "arm64" ]; then
		exit 1
	fi

	if [ -f "${DISKOUT}/etc/lsb-release" ]; then
		DISTRIB_ID=$(grep '^DISTRIB_ID=' "${DISKOUT}/etc/lsb-release" | awk -F '=' '{print $2}')
		if [ "${DISTRIB_ID}" = "Ubuntu" ]; then
            if [ "${OVERLAYFS}" = "1" ]; then
                # for overlayfs
                replace_sbin_init "/lib/systemd/systemd"    
                # resize emmc/sdcard partition
                resize_partition
            fi
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
	if [ -d prebuilt/udev ]; then
		cp -av prebuilt/udev/lib/udev/* "$DISKOUT/lib/udev"
	fi

	# for VC8000 V4L2 vsi daemon
	cp -rf prebuilt/vsi/vsidaemon ${DISKOUT}/usr/bin

	if [ -f "${DISKOUT}/etc/lsb-release" ]; then
		DISTRIB_RELEASE=$(grep '^DISTRIB_RELEASE=' "${DISKOUT}/etc/lsb-release" | awk -F '=' '{print $2}')
		rootfs_prebuilt_dir=$(realpath ubuntu/prebuilt-app-$DISTRIB_RELEASE)
		if [ -d "${rootfs_prebuilt_dir}" ]; then
			find ${rootfs_prebuilt_dir}/ -maxdepth 1 ! -name 'README.md' ! -path ${rootfs_prebuilt_dir}/ -exec cp -av {} "$DISKOUT" \;
		fi
	fi

	find ${rootfs_common_dir}/ -maxdepth 1 ! -name 'README.md' ! -path ${rootfs_common_dir}/ -exec cp -av {} "$DISKOUT" \;
	if [ -d "${rootfs_src_dir}/disk-private" ]; then
		cp -av "${rootfs_src_dir}/disk-private/"* "$DISKOUT"
	fi
	if [ -x "${rootfs_src_dir}/build_disk_private.sh" ]; then
		"${rootfs_src_dir}/build_disk_private.sh"
	fi

	# suspend
	cp ${DISKZ}etc/rc.suspend ${DISKOUT}/etc/rc.suspend
	cp ${DISKZ}etc/udev/rules.d/99-custom-suspend.rules ${DISKOUT}/etc/udev/rules.d/99-custom-suspend.rules

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

if [ -z "${CROSS}" ]; then
	echo "CROSS=... is undefined"
	exit 1;
fi;

# sub builds need absolute path
CROSS_PATH=$(realpath $(dirname $CROSS)/..)
CROSS_PREFIX=$(basename $CROSS)
CROSS_GCC=${CROSS_PATH}/bin/${CROSS_PREFIX}gcc
CROSS_STRIP=${CROSS_PATH}/bin/${CROSS_PREFIX}strip
CROSS_COMPILE=${CROSS_PATH}/bin/${CROSS_PREFIX}
CROSS_MACHINE=$($CROSS_GCC -dumpmachine)
if ! $CROSS_GCC --version 2>/dev/null && ! $CROSS_GCC -v 2>/dev/null; then
	echo "Not found gcc : $CROSS_GCC"
	exit 1
fi

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

	if [ -d $CROSS_PATH/$CROSS_MACHINE/libc/lib ]; then
		mkdir -p $DISKOUT/lib
		lib_install_dirs="$DISKOUT/lib"
		cp -av $CROSS_PATH/$CROSS_MACHINE/libc/lib/*.so* $DISKOUT/lib
	fi
	if [ -d $CROSS_PATH/$CROSS_MACHINE/libc/usr/lib ]; then
		mkdir -p $DISKOUT/usr/lib
		lib_install_dirs+=" $DISKOUT/usr/lib"
		cp -av $CROSS_PATH/$CROSS_MACHINE/libc/usr/lib/*.so* $DISKOUT/usr/lib
	fi
	if [ -d $CROSS_PATH/$CROSS_MACHINE/libc/lib64 ]; then
		mkdir -p $DISKOUT/lib64
		lib_install_dirs+=" $DISKOUT/lib64"
		cp -av $CROSS_PATH/$CROSS_MACHINE/libc/lib64/*.so* $DISKOUT/lib64
	fi
	if [ -d $CROSS_PATH/$CROSS_MACHINE/libc/usr/lib64 ]; then
		mkdir -p $DISKOUT/usr/lib64
		lib_install_dirs+=" $DISKOUT/usr/lib64"
		cp -av $CROSS_PATH/$CROSS_MACHINE/libc/usr/lib64/*.so* $DISKOUT/usr/lib64
	fi
	if [ "$STRIP" != "0" ]; then
		for f in $(find $DISKOUT -type f)
		do
			mime_type=$(file -b --mime-type $f)
			if [ "$mime_type" = "application/x-sharedlib" ] ||
			   [ "$mime_type" = "application/x-executable" ] ||
			   [ "$mime_type" = "application/x-pie-executable" ]; then
				strip_files+=" $f"
			fi
		done
		$CROSS_STRIP -p $strip_files
	fi

	cd $DISKOUT
	mkdir -p proc sys mnt tmp var run
	cd -

	echo "Build busybox with new config ($BBXCFG)"
	rm -rf $BBX
	tar xf $BBXZ
	cp -vf $BBXCFG $BBX/.config
	for p in ../busybox/patches/*.patch; do patch -p1 -d $BBX < $p; done
fi

echo "Build busybox"
echo make -C $BBX -j4 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$DISKOUT all
make -C $BBX -j ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$DISKOUT all

echo "Install busybox"
cd $BBX && make -j ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$DISKOUT install
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
	# ADD modprobe parameter for VIP9000 NPU module "galcore" modprobe using
	FILE_GALCORE_ARG="${DISKOUT}/etc/modprobe.d/galcore.conf"
	if [ ! -d ${DISKOUT}/etc/modprobe.d ]; then
		mkdir -p ${DISKOUT}/etc/modprobe.d
	fi
	echo 'options galcore recovery=0 powerManagement=0 showArgs=1 irqLine=197 contiguousBase=0x78000000 contiguousSize=0x8000000' > ${FILE_GALCORE_ARG}
	
	# for overlayfs
	replace_sbin_init "/bin/busybox init"

	if [ "${OVERLAYFS}" = "1" ]; then
cat <<EOF > ${DISKOUT}/etc/init.d/rc.init
#!/bin/sh
if [ -f /etc/init.d/rc.resizefs ];then
        /sbin/resize2fs /dev/mmcblk0p${partition}
        rm /etc/init.d/rc.resizefs
fi
umount -l /rom
rm -rf /overlay /rom

EOF
	chmod +x ${DISKOUT}/etc/init.d/rc.init
	fi

elif [ $V7_BUILD -eq 1 ]; then
	if [ -d prebuilt/resize2fs/v7 ]; then
		cp -av prebuilt/resize2fs/v7/* $DISKOUT
	fi
else
	if [ -d prebuilt/resize2fs/v5 ]; then
		cp -av prebuilt/resize2fs/v5/* $DISKOUT
	fi
fi
