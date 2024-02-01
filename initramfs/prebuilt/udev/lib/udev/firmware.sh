#!/bin/sh -e

DEV_DIR="/sys${DEVPATH}"
FIRMWARE_DIR="/etc/firmware /lib/firmware"

for dir in $FIRMWARE_DIR
do
	[ -e ${dir}/${FIRMWARE} ] || continue
	echo 1 > ${DEV_DIR}/loading
	cat ${dir}/${FIRMWARE} > ${DEV_DIR}/data
	echo 0 > ${DEV_DIR}/loading
	exit 0
done

echo -1 > ${DEV_DIR}/loading
exit 1
