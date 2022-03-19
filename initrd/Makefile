#
# Build a safeboot initrd.cpio
#
O ?= ../build
WORKDIR := $O/initrd

all: $O/init $O/initrd.cpio.xz

$O:
	mkdir -p "$O"

$O/init: init.c
	$(CC) -O3 -W -Wall -o $@ $<

$O/initrd.cpio: files.txt
	./initrd-build $@ $<
	sha256sum $@
$O/initrd.cpio.xz: files.txt
	./initrd-build $@ $<
	sha256sum $@

$O/initrd.cpio.bz: $O/initrd.cpio
	bzip2 -z \
		< "$<" \
	| dd bs=512 conv=sync status=none \
	> "$@.tmp"
	@if ! cmp --quiet "$@.tmp" "$@" ; then \
		mv "$@.tmp" "$@" ; \
	else \
		echo "$@: unchanged" ; \
		rm "$@.tmp" ; \
	fi
	sha256sum $@

