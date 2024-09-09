inherit core-image extrausers

DESCRIPTION = "SP7350 image"
LICENSE = "MIT"

IMAGE_LINGUAS = ""

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"
OELAYOUT_ABI = "12"

# IMAGE_FSTYPES += "ext3 ext4 tar.bz2"
# PACKAGE_INSTALL = "${IMAGE_INSTALL}"

ROOTFS_POSTPROCESS_COMMAND:append = " update_issue;"
IMAGE_POSTPROCESS_COMMAND:append =  " mv_rootfs;"

PV = "1.0"
PR = "r0"

update_issue() {    
    echo "Yocto build ${SDK_VERSION}
" > ${IMAGE_ROOTFS}/etc/issue
    echo "${MACHINE}-${BOARDNAME}" > ${IMAGE_ROOTFS}/etc/hostname

    # Root auto login
    sed -i '/\/agetty/ s|\/agetty|& -a root|' ${IMAGE_ROOTFS}/lib/systemd/system/serial-getty@.service 
}

mv_rootfs() {
    ROOTFS_PATH="${BASE_WORKDIR}/${MACHINE}-${DISTRO}-linux/img-${MACHINE}/${PV}-${PR}"
    if [ -d "${ROOTFS_PATH}/rootfs" ]; then 
        rm -rf ${BBLAYERS_FETCH_DIR}/../disk
        mv ${ROOTFS_PATH}/rootfs ${BBLAYERS_FETCH_DIR}/../disk
    fi
}

BUSYBOX_CONFIG_LSUSB = ""

IMAGE_INSTALL = " \
    kernel-modules \
    coreutils \
    glibc-utils \
    findutils \
    grep \
    diffutils \
    dialog \
    ldd \
    curl \
    wget \
    rsyslog \
    wpa-supplicant \
    mtd-utils \
    mtd-utils-ubifs \
    cifs-utils \
    usbutils \
    lsof \
    strace \
    minicom \
    nano \
    init-ifupdown \
    initscripts \
    net-tools \
    apt \
    gnupg \
    sudo \
    glibc \
    util-linux \
    e2fsprogs \
    e2fsprogs-mke2fs \
    dosfstools \
    openssh-sftp \
    tcpdump \
    openssh \
    e2fsprogs-resize2fs \
    iperf3 \
    glib-2.0 \
    glib-2.0-dev \
    gstreamer1.0-dev \
    v4l-utils \
    parted \
    dhcpcd \
    shadow \
    perl \
    base-passwd \
    libpam \
    udev \
    python3-evdev \
    systemd \
"
# IMAGE_INSTALL:append = " qtbase"
# IMAGE_INSTALL:append = " matchbox-desktop matchbox-wm matchbox-panel matchbox-keyboard xserver-xf86-config matchbox-session matchbox-terminal"
# IMAGE_INSTALL:append = " xserver-xorg xinit xauth xterm xclock font-alias font-misc-misc xf86-video-modesetting xf86-video-fbdev twm"
# IMAGE_INSTALL:append = " adwaita-icon-theme  mesa mesa-driver-swrast"
