SRC_DIR_LINUX=linux
SRC_DIR_BUSYBOX=busybox
BUILD_DIR_LINUX=build/linux
BUILD_DIR_BUSYBOX=build/busybox
BUILD_DIR_INITRAMFS=build/initramfs
DIST_DIR=dist

MAKE_LINUX=$(MAKE) -C linux O=../$(BUILD_DIR_LINUX)
MAKE_BUSYBOX=$(MAKE) -C busybox O=../$(BUILD_DIR_BUSYBOX)

clean:
		rm -rf dist build
		mkdir -p dist $(BUILD_DIR_LINUX) $(BUILD_DIR_BUSYBOX) $(BUILD_DIR_INITRAMFS)

build: clean config-linux build-linux config-busybox build-busybox build-initramfs

config-linux:
		$(MAKE_LINUX) allnoconfig
		#$(MAKE_LINUX) kvm_guest.config
		KCONFIG_CONFIG=$(BUILD_DIR_LINUX)/.config $(SRC_DIR_LINUX)/scripts/kconfig/merge_config.sh -m $(BUILD_DIR_LINUX)/.config linux_minimal_qemu.config
		$(MAKE_LINUX) oldconfig

build-linux:
		$(MAKE_LINUX) -j$(shell nproc)
		cp $(BUILD_DIR_LINUX)/arch/x86/boot/bzImage $(DIST_DIR)
		cp $(BUILD_DIR_LINUX)/vmlinux $(DIST_DIR)

config-busybox:
		$(MAKE_BUSYBOX) defconfig
		sed '/# CONFIG_STATIC /s/.*/CONFIG_STATIC=y/' -i $(BUILD_DIR_BUSYBOX)/.config;
		sleep 1

build-busybox:
		$(MAKE_BUSYBOX) -j$(shell nproc)
		$(MAKE_BUSYBOX) install

build-initramfs:
		mkdir -pv $(BUILD_DIR_INITRAMFS)/{bin,sbin,etc,proc,sys,usr/{bin,sbin}}
		cp -av $(BUILD_DIR_BUSYBOX)/_install/* $(BUILD_DIR_INITRAMFS)
		cp init $(BUILD_DIR_INITRAMFS)
		cd $(BUILD_DIR_INITRAMFS) && find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../../$(DIST_DIR)/initramfs.cpio.gz
	
qemu:
		qemu-system-x86_64 -cpu host -enable-kvm -kernel $(DIST_DIR)/bzImage -initrd $(DIST_DIR)/initramfs.cpio.gz -nographic -append "console=ttyS0"

qemu-gdb:
	qemu-system-x86_64 -cpu host -enable-kvm -kernel $(DIST_DIR)/bzImage -initrd $(DIST_DIR)/initramfs.cpio.gz -nographic -append "console=ttyS0 nokaslr" -gdb tcp::1234 -S

gdb:
	gdb -ex "file $(DIST_DIR)/vmlinux" -ex "target remote :1234"
