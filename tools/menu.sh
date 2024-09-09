# shellcheck shell=bash disable=SC2034
menu_rootfs_title_num()
{
	local config=''
	local configs=''
	local config_folder=''
	local rootfs_type=''
	local rootfs_title=''
	local rootfs_archive=''
	local rootfs_title_priority=''
	local search_dirs='linux/rootfs/'

	# <priority>:<type>:<title>:[folder]:[archive]\n
	MENU_ROOTFS_TITLES='1:BUSYBOX:BusyBox 1.31.1::\n'
	MENU_ROOTFS_TITLES+='1099:BUILDROOT:Buildroot 2024.02::\n'
	MENU_ROOTFS_TITLES+='1199:YOCTO:Yocto 4.2.3::\n'

	configs=$(find $search_dirs -maxdepth 4 -type f -name 'menu.config')
	for config in $configs
	do
		rootfs_type=$(grep '^ROOTFS_TYPE=' "$config" | awk -F '=' '{print $2}' | tr '[:lower:]' '[:upper:]')
		rootfs_title=$(grep '^ROOTFS_TITLE=' "$config" | awk -F '=' '{print $2}')
		rootfs_title_priority=$(grep '^ROOTFS_TITLE_PRIORITY=' "$config" | awk -F '=' '{print $2}')
		rootfs_archive=$(grep '^ROOTFS_ARCHIVE=' "$config" | awk -F '=' '{print $2}')
		config_folder=$(dirname "$config")
		config_folder=$(basename "$config_folder")
		[ -z "$rootfs_type" ] && continue
		[ -z "$rootfs_title" ] && rootfs_title="$config_folder"
		[ -z "$rootfs_title_priority" ] && rootfs_title_priority=999
		MENU_ROOTFS_TITLES+="$rootfs_title_priority:$rootfs_type:$rootfs_title:$config_folder:$rootfs_archive\n"
	done
	MENU_ROOTFS_NUM=$(echo -n -e "$MENU_ROOTFS_TITLES" | wc -l)
}

menu_rootfs_title()
{
	if [ -n "$1" ]; then
		echo -n -e "$MENU_ROOTFS_TITLES" | sort -b -t ':' -k1,1n -k3,3 | awk -F ':' 'NR=='"$1"' {print $3}'
	fi
}

menu_rootfs_content()
{
	if [ -n "$1" ]; then
		echo -n -e "$MENU_ROOTFS_TITLES" | sort -b -t ':' -k1,1n -k3,3 | \
			awk  -F ':' 'NR=='"$1"' {printf $2; {if ($4 != "") {printf ":"$4; if ($5 != "") printf ":"$5}}}'
	fi
}
