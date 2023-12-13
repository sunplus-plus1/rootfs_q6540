#!/bin/bash

HOSTNAME='ubuntu'
ROOT_PASSWORD='root'
USER_NAME='sunplus'
USER_PASSWORD='sunplus'

ARCH='arm64'
UBUNTU_ID='20.04'
UBUNTU_CODENAME='focal'
UBUNTU_ROOTFS="ubuntu-server-${UBUNTU_ID}-rootfs-${ARCH}"
UBUNTU_BASE_ID="${UBUNTU_ID}.5"
UBUNTU_BASE_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_ID}/release"
UBUNTU_BASE_NAME="ubuntu-base-${UBUNTU_BASE_ID}-base-${ARCH}.tar.gz"

UBUNTU_APT_SOURCE_RESTORE_FROM_BACKUP='true'
UBUNTU_APT_SOURCE_URL='http://ports.ubuntu.com'

UBUNTU_APT_SOURCES_LIST="\
deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME} main restricted
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME} main restricted

deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-updates main restricted
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-updates main restricted

deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME} universe
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME} universe
deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-updates universe
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-updates universe

deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME} multiverse
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME} multiverse
deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-updates multiverse
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-updates multiverse

deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-backports main restricted universe multiverse
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-backports main restricted universe multiverse

deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-security main restricted
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-security main restricted
deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-security universe
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-security universe
deb ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-security multiverse
# deb-src ${UBUNTU_APT_SOURCE_URL}/ubuntu-ports/ ${UBUNTU_CODENAME}-security multiverse
"

UBUNTU_APT_SOURCES_LIST=""
UBUNTU_APT_SOURCES_LIST_FILE="${UBUNTU_ROOTFS}/etc/apt/sources.list"
UBUNTU_PACKAGES="ubuntu-server sudo netplan.io \
net-tools network-manager iputils-ping openssh-server"

rootfs_base()
{
    if [ ! -f ${UBUNTU_BASE_NAME} ]; then
        wget ${UBUNTU_BASE_URL}/${UBUNTU_BASE_NAME}
    fi
    rm  -rf $UBUNTU_ROOTFS
    mkdir -p $UBUNTU_ROOTFS
    tar -xf ${UBUNTU_BASE_NAME} -C ${UBUNTU_ROOTFS}

    if [ -x ${UBUNTU_ROOTFS}/usr/bin/qemu-aarch64-static ]; then 
        cp /usr/bin/qemu-aarch64-static ${UBUNTU_ROOTFS}/usr/bin
    fi

    chmod 0777 ${UBUNTU_ROOTFS}/tmp

    echo "nameserver 8.8.8.8" > ${UBUNTU_ROOTFS}/etc/resolv.conf

    if [ "${UBUNTU_APT_SOURCES_LIST}" != "" ]; then 
        if [ ! -f ${UBUNTU_APT_SOURCES_LIST_FILE}.backup ]; then
            cp ${UBUNTU_APT_SOURCES_LIST_FILE} ${UBUNTU_APT_SOURCES_LIST_FILE}.backup
        fi
        echo "${UBUNTU_APT_SOURCES_LIST}" > ${UBUNTU_APT_SOURCES_LIST_FILE}
    fi
}

rootfs_mount()
{
    mount -t proc /proc ${UBUNTU_ROOTFS}/proc
    mount -t sysfs /sys ${UBUNTU_ROOTFS}/sys
    mount -o bind /dev ${UBUNTU_ROOTFS}/dev
    mount -o bind /dev/pts ${UBUNTU_ROOTFS}/dev/pts
}

__rootfs_umount()
{
    while $(mountpoint -q ${UBUNTU_ROOTFS}/$1)
    do
        umount -lR ${UBUNTU_ROOTFS}/$1
    done

}
rootfs_umount()
{
    __rootfs_umount proc
    __rootfs_umount sys
    __rootfs_umount dev
}

rootfs_install()
{
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "apt update"
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "apt-get -y upgrade"
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "apt-get install -y ${UBUNTU_PACKAGES}"
}

rootfs_config()
{
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "echo ${HOSTNAME} > /etc/hostname" 
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "echo -e \"${ROOT_PASSWORD}\n${ROOT_PASSWORD}\"|passwd root" 
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "echo -e \"${USER_PASSWORD}\n${USER_PASSWORD}\n\n\n\n\n\n\"|adduser --quiet ${USER_NAME}" 
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "echo -n '\
network:
    version: 2
    renderer: NetworkManager
'" > ${UBUNTU_ROOTFS}/etc/netplan/01-network-manager-all.yaml
}

rootfs_clean()
{
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "systemctl disable multipathd.service" 
    chroot ${UBUNTU_ROOTFS} /bin/bash -c "systemctl disable NetworkManager-wait-online.service" 

    chroot ${UBUNTU_ROOTFS} /bin/bash -c "apt clean"
    rm -rf ${UBUNTU_ROOTFS}/var/lib/apt/lists/*

    chmod 0755 ${UBUNTU_ROOTFS}/var/lib/snapd/void

    if [ "${UBUNTU_APT_SOURCE_RESTORE_FROM_BACKUP}" == "true" ]; then
        if [ -f ${UBUNTU_APT_SOURCES_LIST_FILE}.backup ]; then
            mv ${UBUNTU_APT_SOURCES_LIST_FILE}.backup ${UBUNTU_APT_SOURCES_LIST_FILE}
        fi
    fi
    rm -rf ${UBUNTU_ROOTFS}/usr/bin/qemu-aarch64-static
}

rootfs_output()
{
    tar --numeric-owner -cvzf ${UBUNTU_ROOTFS}.tar.gz ${UBUNTU_ROOTFS}
}

rootfs_signal()
{
    rootfs_umount
    exit 0
}

trap "rootfs_signal" 2

main()
{
    rootfs_umount

    rootfs_base
    rootfs_mount
    rootfs_install
    rootfs_config
    rootfs_clean
    rootfs_umount
    rootfs_output
}

main
