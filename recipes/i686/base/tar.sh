#!/bin/bash
set -euo pipefail

pkgname="tar"
pkgver="1.35"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/tar/tar-1.35.tar.xz")
sha256sums=("4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16")
depends=("acl" "attr" "bzip2" "glibc" "gzip" "xz")

makedepends=("acl" "attr" "bash" "binutils" "bison" "coreutils" "gcc" "gettext" "glibc" "grep" "inetutils" "make" "sed" "texinfo")
description="tar"

build() {
cd $srcdir
tar -xf $srcdir/tar-$pkgver.tar.xz
cd $srcdir/tar-$pkgver

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/tar-$pkgver
make DESTDIR="$pkgdir" install
make DESTDIR="$pkgdir" -C doc install-html docdir=/usr/share/doc/tar
}
