TARGET ?= jump
INITRD ?= build/initrd-$(TARGET).cpio
BUNDLE ?=
CMDLINE ?= quiet console=ttyS0 ip=::::$(TARGET)
KERNEL ?= build/vmlinuz-$(if $(BUNDLE),$(TARGET),virtio)

all: keys $(KERNEL) $(INITRD)

build/vmlinuz-virtio: $(if $(BUNDLE),$(INITRD))
	+./linux-builder/linux-builder \
		--version 5.4.117 \
		--config linux-builder/config/linux-virtio.config \
		$(if $(BUNDLE), \
			--initrd "$(INITRD)" \
			--hostname "$(TARGET)" \
			--cmdline "$(CMDLINE)" \
			--tag "$(TARGET)" \
		,
			--tag "virtio" \
		)

# see linux/Documentation/filesystems/nfs/nfsroot.txt
# if client-ip is INADDR_ANY (or empty), autoconfig will run
#ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>:

menuconfig:
	./linux-builder/linux-builder \
		--config linux-builder/config/linux-qemu.config \
		--tag "jump" \
		--menuconfig

INITRD_CONFIG = \
	linux-builder/config/initrd-base.config \
	base/initrd.config \
	syslogd/initrd.config \

build/initrd-%.cpio: %/initrd.config $(INITRD_CONFIG)
	./linux-builder/initrd-builder \
		-v \
		--relative \
		-o $@ \
		$(INITRD_CONFIG) \
		$<

keys: build/etc/user_ca
keys: build/etc/host_ca
keys: build/etc/ssh/ssh_host_rsa_key-cert.pub
keys: build/etc/testuser_rsa-cert.pub

# Create separate CA keys for the user and host system
build/etc/user_ca:
	@echo '*********** Creating CA to sign user keys *********'
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f "$@" \
		-C "jump-user-CA"
build/etc/host_ca:
	@echo '*********** Creating CA to sign host keys *********'
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f "$@" \
		-C "jump-host-CA"

# Create a signed host key for the jump host
build/etc/ssh/ssh_host_rsa_key:
	@echo '*********** Creating a jump host key *********'
	mkdir -p $(dir $@)
	ssh-keygen \
		-h \
		-t rsa \
		-b 4096 \
		-N '' \
		-f $@

build/etc/ssh/ssh_host_rsa_key-cert.pub: build/etc/ssh/ssh_host_rsa_key build/etc/host_ca
	@echo '*********** Signing the jump host key *********'
	ssh-keygen \
		-s build/etc/host_ca \
		-h \
		-I jump \
		-n jump,safeboot \
		-V +52w \
		$<.pub

# Create a test user that is signed with the key
build/etc/testuser_rsa:
	@echo '*********** Creating test user key *********'
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f $@
build/etc/testuser_rsa-cert.pub: build/etc/testuser_rsa build/etc/user_ca.pub
	@echo '*********** Signing test user key *********'
	ssh-keygen \
		-s build/etc/user_ca \
		-I test-user \
		-n jump \
		-V +1h \
		$<.pub

$(INITRD): | linux-builder/init
$(INITRD): build/etc/ssh/ssh_host_rsa_key-cert.pub
linux-builder/init:
	$(MAKE) -C $(dir $@) $(notdir $@)

# initrd is built into the kernel now
NO=-initrd $(INITRD) \

qemu: $(KERNEL) $(INITRD)
	qemu-system-x86_64 \
		-M q35,accel=kvm \
		-m 512 \
		-kernel "$(KERNEL)" \
		$(if $(BUNDLE),, \
			-initrd "$(INITRD)" \
			-append "$(CMDLINE)" \
		) \
		-netdev user,id=eth0,hostfwd=tcp::5555-:22,hostfwd=tcp::8080-:80 \
		-device virtio-net-pci,netdev=eth0 \
		-serial stdio \


#		-device virtio-serial-pci,id=virtio-serial0              \
#		-chardev stdio,id=charconsole0                           \
#		-device serial,chardev=charconsole0,id=console0  \

# -device virtconsole,chardev=charconsole0,id=console0  \
