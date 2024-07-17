#!/bin/sh

mount --make-rprivate /
resize2fs /dev/mmcblk0p9
mount /dev/mmcblk0p9 /overlay
mkdir -p /overlay/upper
mkdir -p /overlay/work
mkdir -p /overlay/lower
mount --make-private /overlay 
mount --move /proc /mnt/proc
mount -t overlay overlay -o lowerdir=/,upperdir=/overlay/upper,workdir=/overlay/work /mnt
pivot_root /mnt /mnt/rom
mount --move /rom/proc /proc
mount --move /rom/var /var
mount --move /rom/dev /dev
mount --move /rom/tmp /tmp
mount --move /rom/sys /sys
mount --move /rom/lib /lib
mount --move /rom/run /run

mount --move /rom/overlay /overlay
mount --make-shared /overlay 
mount --make-shared /

##########################################################

# mount --move /rom/etc /etc
# mount --move /rom/usr /usr
# umount -l /overlay
# umount -l /rom
# rm -rf /overlay /rom
