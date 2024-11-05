TIMEOUT=2
BINFILE=a926.img
MMCPART=/dev/mmcblk0p5
NANDPART=/dev/mtd6
MOUNT_DIR=/mnt/usb
MMC_BLOCKSIZE=512
writeflag=0

__umount()
{
	umount $MOUNT_DIR 2> /dev/null
}

__writebin()
{
	writeflag=0
	if [ ! -f $MOUNT_DIR/$BINFILE ]; then
			echo "$1 no $BINFILE file to update!!!"
	else
			binsize=$(ls -l /mnt/usb/$BINFILE | awk '{print $5}')
			echo "@BINFILE size=$binsize"
			if [ -b $MMCPART ]; then
				binsize=$(($binsize/$MMC_BLOCKSIZE+1))
				echo write $MOUNT_DIR/$BINFILE to $MMCPART
				dd if=$MOUNT_DIR/$BINFILE of=$MMCPART bs=$MMC_BLOCKSIZE count=$binsize
				writeflag=1
			elif [ -c $NANDPART ]; then
				echo write $MOUNT_DIR/$BINFILE to $NANDPART 
				mtdupdate $NANDPART $MOUNT_DIR/$BINFILE
				writeflag=1
			else
				echo "no mmc or nand device!!!"
			fi
	fi
}
__mount()
{
		umount /mnt 2> /dev/null
		mkdir -p $2
		while [ $TIMEOUT -gt 0 ]
		do
			TIMEOUT=$(($TIMEOUT-1))
			[ -e $1 ] && break
			sleep 1
		done
		umount $2 2> /dev/null
		if [ -e ${1}p1 ]; then
			e2fsck -y ${1}p1 $2 2> /dev/null
			mount ${1}p1 $2 2> /dev/null
		elif [ -e ${1}1 ]; then
			e2fsck -y ${1}1 $2 2> /dev/null
			mount ${1}1 $2 2> /dev/null
		else
			e2fsck -y $1 $2 2> /dev/null
			mount $1 $2 2> /dev/null
		fi
}
_write()
{
	__mount $1 $2
	__writebin
	__umount
}
echo " ##### used /dev/sda to update ###"
_write /dev/sda $MOUNT_DIR
if [ $writeflag -eq 0 ]; then #not write success,try /dev/sdb
	echo " ###### used /dev/sdb1 to update ###"
	_write /dev/sdb $MOUNT_DIR
fi
