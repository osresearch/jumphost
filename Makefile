all: keys build/vmlinuz build/initrd.cpio.xz

keys: etc/user_ca
keys: etc/host_ca
keys: build/etc/ssh/ssh_host_rsa_key-cert.pub
keys: etc/testuser_rsa-cert.pub

# Create separate CA keys for the user and host system
etc/user_ca:
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f "$@" \
		-C "jump-user-CA"
etc/host_ca:
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
etc/testuser_rsa:
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f $@
etc/testuser_rsa-cert.pub: etc/testuser_rsa
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
		-serial stdio \
		-kernel ./build/vmlinuz \
		-initrd ./build/initrd.cpio.xz \
		-append "console=ttyS0 ip=dhcp" \
		-netdev user,id=eth0,hostfwd=tcp::5555-:22 \
		-device e1000,netdev=eth0 \

build/vmlinuz:
	$(MAKE) -C kernel
build/initrd.cpio.xz:
	$(MAKE) -C initrd


