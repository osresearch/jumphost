# jumphost

These scripts produce a minimal OpenSSH jump host, which will
accept signed user keys and allow them to transfer to another
host inside the network.  The build system uses
[linux-builder](https://github.com/osresearch/linux-builder)
to create a custom kernel and initrd with only the `sshd` program.

Goals:

* [X] Diskless image
* [X] Immutable system
* [X] Network logging
* [X] No shell for accidental code execution
* [X] Minimal attack surface

## Building

```
git clone --recursive https://github.com/osresearch/jumphost
cd jumphost
make keys # create CA keys and a demo user
make -j32 build/vmlinuz-jump
make qemu
```

## Running with libvirt

```
virsh create jump/jump.xml
```

## Signed user keys

* https://smallstep.com/blog/use-ssh-certificates/
* https://www.vaultproject.io/docs/secrets/ssh/signed-ssh-certificates

Every user logs into the jump host as user `jump`. Passwords are not
allowed. Interactive sessions are not allowed.  Only proxy commands
via the `ssh -J jump@jumphost user@other-host` are allowed.

The jumphost has a public key of the user CA that will sign acceptable
user keys.  This CA is fixed at image build time; to change the CA requires
rebuilding the jump host system image.  The login attempts are sent
via syslog to the network logging host.

## Signed host keys

The jumphost's host key is also signed by a host CA, so that users
connecting can ensure that they trust it without having to TOFU
(Trust On First Use) the key.

You can add it to your user ssh config by running:

```
echo "@cert-authority * $(cat etc/host_ca.pub)" >> ~/.ssh/known_hosts
```
