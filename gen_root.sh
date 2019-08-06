OUT_IMG=rootfs.img
WORK_DIR=./initramfs/disk

if [ 0 -eq 1 ];then
##########  squash fs ############
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

else
##########  ext2 fs ############
EXT2=./tools/mke2fs

if [ "$1" != "" ];then
	OUT_IMG=$1
fi

if [ ! -d $WORK_DIR ];then
	echo "Error: $WORK_DIR doesn't exist!"
	exit 1
fi

sz=`du -sb $WORK_DIR | cut -f1`
echo "rootfs total size =$sz B"
# 5% block reserved for superusers ,used 10% to calculation(mke2fs -m optiton)
sz=$((sz*100/90))
EXT2_SIZE=$((sz/1024/1024+1))
echo "rootfs create size = $EXT2_SIZE M"
rm -rf $OUT_IMG

$EXT2 -d "$WORK_DIR" -m 5 -b 4096 $OUT_IMG $((EXT2_SIZE))M 

fi

