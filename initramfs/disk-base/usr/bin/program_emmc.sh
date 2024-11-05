#!/bin/sh

#Create gpt table; align 2 sector
(echo "o
Y
x
l
2
m"
#Create partition uboot1
echo "n
1
34
2081

c
uboot1"
#Create partition uboot2
echo "n
2
2082
4129

c
2
uboot2"
#Create partition fip
echo "n
3
4130
6177

c
3
fip"
#Create partition env
echo "n
4
6178
7201

c
4
env"
#Create partition env_redund
echo "n
5
7202
8225

c
5
env_redund"
#Create partition dtb
echo "n
6
8226
8737

c
6
dtb"
#Create partition kernel
echo "n
7
8738
74273

c
7
kernel"
#Create partition rootfs
echo "n
8
74274
15269854

c
8
rootfs"
#Save and exit
echo "w
Y")|gdisk /dev/mmcblk0

mount /dev/sda4 /mnt
echo 0 > /sys/block/mmcblk0boot0/force_ro
dd if=/mnt/xboot.img of=/dev/mmcblk0boot0 conv=fsync
echo 1 > /sys/block/mmcblk0boot0/force_ro

dd if=/mnt/u-boot.img of=/dev/mmcblk0p2 conv=fsync
dd if=/mnt/fip.img of=/dev/mmcblk0p3 conv=fsync
dd if=/mnt/uImage of=/dev/mmcblk0p7 conv=fsync
dd if=/mnt/rootfs.img of=/dev/mmcblk0p8 conv=fsync
umount /mnt