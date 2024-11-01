inherit core-image extrausers

DESCRIPTION = "SP7350 image"
LICENSE = "MIT"

IMAGE_LINGUAS = ""

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"
OELAYOUT_ABI = "12"

# IMAGE_FSTYPES += "ext3 ext4 tar.bz2"
# PACKAGE_INSTALL = "${IMAGE_INSTALL}"
EXTRA_USERS_PARAMS += " usermod -p \`openssl passwd -1 123\` root;"

ROOTFS_POSTPROCESS_COMMAND:append = " update_issue;"
IMAGE_POSTPROCESS_COMMAND:append =  " mv_rootfs;"

PV = "1.0"
PR = "r0"

update_issue() {    
    echo "Yocto build ${SDK_VERSION}
" > ${IMAGE_ROOTFS}/etc/issue
    echo "${MACHINE}-${BOARDNAME}" > ${IMAGE_ROOTFS}/etc/hostname
}

mv_rootfs() {
    ROOTFS_PATH="${BASE_WORKDIR}/${MACHINE}-${DISTRO}-linux/img-${MACHINE}/${PV}-${PR}"
    echo "$ROOTFS_PATH" > ${BBLAYERS_FETCH_DIR}/rootfs_path
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
    openssh-sftp-server \
    e2fsprogs-resize2fs \
    e2fsprogs-tune2fs \
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
    udev \
    python3-evdev \
    systemd \
    openssl \
    rsync \
    tslib \
    swupdate \
    cpio \
"

IMAGE_INSTALL:append = " busybox"
PACKAGECONFIG:append = " vi"
IMAGE_INSTALL:append = " qtbase"
