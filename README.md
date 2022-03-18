# jumphost

These scripts produce a minimal OpenSSH jump host, which will
accept signed user keys and allow them to transfer to another
host inside the network.

Goals:

* Diskless image
* Immutable system
* Network logging
* No shell for accidental code execution
* Minimal attack surface

## Signed user keys

* https://smallstep.com/blog/use-ssh-certificates/
* https://www.vaultproject.io/docs/secrets/ssh/signed-ssh-certificates

The jumphost has a public key of the CA that will sign acceptable user keys.
The jumphost's host key is also signed by the same CA, so that users connecting
can ensure that they trust it.
