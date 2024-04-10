## etc/rc.local

The file etc/rc.local is used for systemd rc-local.service, and its actions are:
1. Do CM4-REMOTEPROC.
2. Change NPU(galcore) device file attribute.
3. Extend rootfs partition and resize partition base on disk size limitation.

## lib/systemd/system/systemd-suspend.service

The file lib/systemd/system/systemd-suspend.service is used for systemd suspend.service.
File is patched for AP6256 wifi suspend issue, that does "/usr/sbin/ip link set down wlan0" before system suspend.

## etc/modprobe.d/galcore.conf

Add modprobe parameter for VIP9000 NPU module "galcore" modprobe using
