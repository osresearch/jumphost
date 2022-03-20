INITRD ?= build/initrd.cpio.xz
KERNEL ?= build/vmlinuz-jump
	
all: keys $(KERNEL) $(INITRD)

build/vmlinuz-%: config/%.config
	+./initrd/linux-build \
		-v -v \
		--version 5.4.117 \
		--config $<

etc:
	mkdir -p $@

keys: etc/user_ca
keys: etc/host_ca
keys: build/etc/ssh/ssh_host_rsa_key-cert.pub
keys: etc/testuser_rsa-cert.pub

# Create separate CA keys for the user and host system
etc/user_ca: | etc
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f "$@" \
		-C "jump-user-CA"
etc/host_ca: | etc
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f "$@" \
		-C "jump-host-CA"

# Create a signed host key for the jump host
build/etc/ssh/ssh_host_rsa_key:
	mkdir -p $(dir $@)
	ssh-keygen \
		-h \
		-t rsa \
		-b 4096 \
		-N '' \
		-f $@

build/etc/ssh/ssh_host_rsa_key-cert.pub: build/etc/ssh/ssh_host_rsa_key etc/host_ca
	ssh-keygen \
		-s etc/host_ca \
		-h \
		-I jump \
		-n jump,safeboot \
		-V +52w \
		$<.pub

# Create a test user that is signed with the key
etc/testuser_rsa: | etc
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f $@
etc/testuser_rsa-cert.pub: etc/testuser_rsa | etc
	ssh-keygen \
		-s etc/user_ca \
		-I test-user \
		-n jump \
		-V +1h \
		$<.pub


qemu: all
	qemu-system-x86_64 \
		-M q35 \
		-m 512 \
		-kernel $(KERNEL) \
		-initrd $(INITRD) \
		-append "console=hvc0 ip=dhcp" \
		-netdev user,id=eth0,hostfwd=tcp::5555-:22 \
		-device virtio-net-pci,netdev=eth0 \
		-device virtio-serial-pci,id=virtio-serial0              \
		-chardev stdio,id=charconsole0                           \
		-device virtconsole,chardev=charconsole0,id=console0  \

build/vmlinuz:
	$(MAKE) -C kernel
build/initrd.cpio.xz: initrd/files.txt
	$(MAKE) -C initrd ../$@
build/initrd.cpio: initrd/files.txt
	$(MAKE) -C initrd ../$@


