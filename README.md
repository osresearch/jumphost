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
