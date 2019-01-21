.PHONY: rootfs initramfs initramfs_update clean

# v5 or v7
rootfs_cfg ?= v7

rootfs: initramfs_update
	@./gen_root.sh

initramfs:
	@cd initramfs ; ./build_disk.sh ${rootfs_cfg} ; cd -

initramfs_update:
	@cd initramfs ; \
	 if [ ! -d disk ];then \
		./build_disk.sh ${rootfs_cfg} ; \
	 else \
		./build_disk.sh ${rootfs_cfg} update ; \
	 fi ; \
	 cd -

clean:
	@rm -rf rootfs.img initramfs/disk/ initramfs/busybox-1.24.1/
