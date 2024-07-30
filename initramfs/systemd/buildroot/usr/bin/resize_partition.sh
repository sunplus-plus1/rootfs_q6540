#!/bin/sh

## SDCARD : DEVPART=2 => ext4    partition
## EMMC   : DEVPART=8 => rootfs  partition 
## EMMC   : DEVPART=9 => overlay partition 

if [ "$DEVTYPE" = "EMMC" ]; then
  DEVICE=/dev/mmcblk0
elif [ "$DEVTYPE" = "SDCARD" ]; then
  DEVICE=/dev/mmcblk1
else
  echo "Device $DEVTYPE not supported!"
  exit 1 	
fi

PARTITION=${DEVICE}p${DEVPART}

# Ensure the partition exists
if [ ! -b "$PARTITION" ]; then
    echo "Partition $PARTITION not found!"
    exit 1
fi

# Resize the partition using parted
if [ "$DEVTYPE" = "SDCARD" ]; then
  parted $DEVICE resizepart 2 100%
  if [ "$?" != "0" ]; then
    echo "parted failed!"
    exit 1
  fi
fi

# Resize the filesystem
resize2fs $PARTITION

if [ "$?" != "0" ]; then
  echo "resize2fs failed!"
  exit 1
fi

MULTI_USER_TARGET_WANTS=/etc/systemd/system/multi-user.target.wants
if [ -L "$MULTI_USER_TARGET_WANTS/resize_partition.service" ]; then
  rm $MULTI_USER_TARGET_WANTS/resize_partition.service
fi

echo "Partition $PARTITION resized to maximum capacity."
