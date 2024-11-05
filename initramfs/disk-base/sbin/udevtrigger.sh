#!/bin/sh -e

IFS=$'\n'

for uevent in $(find /sys/devices -name uevent -type f)
do
	dir=${uevent%/*}
	if [ ! -f ${dir}/dev ]; then
		if [ ! -f ${dir}/data -o ! -f ${dir}/loading ]; then
			continue
		fi
		if [ $(realpath ${dir}/subsystem) != '/sys/class/firmware' ]; then
			continue
		fi
	fi
	echo -n 'add' > $uevent
done
