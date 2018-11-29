.PHONY: rootfs initramfs initramfs_update clean

rootfs: initramfs_update
	@./gen_root.sh

initramfs:
	@cd initramfs ; ./build_disk.sh ; cd -

initramfs_update:
	@cd initramfs ; \
	 if [ ! -d disk ];then \
		./build_disk.sh ; \
	 else \
		./build_disk.sh update ; \
	 fi ; \
	 cd -

clean:
	@rm -rf rootfs.img initramfs/disk/ initramfs/busybox-1.24.1/
