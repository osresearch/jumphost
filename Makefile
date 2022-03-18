all: build/vmlinuz build/initrd.cpio.xz

qemu: all
	qemu-system-x86_64 \
		-M q35 \
		-m 512 \
		-serial stdio \
		-kernel ./build/vmlinuz \
		-initrd ./build/initrd.cpio.xz \
		-append "console=ttyS0 quiet ip=dhcp" \
		-netdev user,id=eth0,hostfwd=tcp::5555-:22 \
		-device e1000,netdev=eth0 \

build/vmlinuz:
	$(MAKE) -C kernel
build/initrd.cpio.xz:
	$(MAKE) -C initrd

