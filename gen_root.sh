OUT_IMG=rootfs.img
WORK_DIR=./initramfs/disk
MKSQFS_COMPOPT="-comp lzo -Xcompression-level 9"
MKSQFS=./tools/mksquashfs

if [ "$1" != "" ];then
	OUT_IMG=$1
fi

if [ ! -d $WORK_DIR ];then
	echo "Error: $WORK_DIR doesn't exist!"
	exit 1
fi

$MKSQFS $WORK_DIR $OUT_IMG -all-root -noappend $MKSQFS_COMPOPT
