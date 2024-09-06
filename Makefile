.PHONY: rootfs initramfs initramfs_update clean

ARCH ?= arm
# v5 or v7
rootfs_cfg ?= v7
# EMMC NAND SPINOR SDCARD
boot_from ?= EMMC

rootfs: initramfs_update
	@OVERLAYFS=${OVERLAYFS} ./gen_root.sh ${boot_from} ${FLASH_SIZE} ${NAND_PAGE_SIZE} ${NAND_PAGE_CNT}

initramfs:
	@cd initramfs; export ARCH=$(ARCH); export CROSS=$(CROSS); export ROOTFS_CONTENT=$(ROOTFS_CONTENT); export boot_from=$(boot_from); export OVERLAYFS=${OVERLAYFS}; ./build_disk.sh ${rootfs_cfg}; cd -

initramfs_update:
	@$(eval ROOTFS_DIR := $(shell echo `pwd`/initramfs/disk)) \
	if [ ! -f "$(ROOTFS_DIR)/usr/bin/adckey" ]; then \
		make -C tools/adckey clean; \
		make -C tools/adckey all CROSS=$(CROSS); \
		if [ $$? -ne 0 ]; then \
			exit 1; \
		fi; \
		make -C tools/adckey install ROOTFS_DIR=$(ROOTFS_DIR); \
	fi
	@cd initramfs ; \
	 if [ ! -d disk ];then \
		export ARCH=$(ARCH); export CROSS=$(CROSS); export ROOTFS_CONTENT=$(ROOTFS_CONTENT); export boot_from=$(boot_from); ./build_disk.sh ${rootfs_cfg} ; \
	 else \
		export ARCH=$(ARCH); export CROSS=$(CROSS); export ROOTFS_CONTENT=$(ROOTFS_CONTENT); export boot_from=$(boot_from); ./build_disk.sh ${rootfs_cfg} update ; \
	 fi ; \
	 cd -

clean:
	@rm -rf rootfs.img initramfs/disk/ initramfs/busybox-1.31.1/ initramfs/.tmp/
