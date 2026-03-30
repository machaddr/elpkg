#!/bin/bash
set -euo pipefail

pkgname="sed"
pkgver="4.9"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/sed/sed-4.9.tar.xz")
sha256sums=("6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181")
depends=("acl" "attr" "glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "grep" "make" "texinfo")
description="sed"

build() {
cd $srcdir
tar -xf $srcdir/sed-$pkgver.tar.xz
cd $srcdir/sed-$pkgver
./configure --prefix=/usr

make -j$(nproc)
make -j$(nproc) html
}

package() {
cd $srcdir/sed-$pkgver

# Install the package and its documentation
make DESTDIR="$pkgdir" install
install -d -m755           "$pkgdir/usr/share/doc/sed"
install -m644 doc/sed.html "$pkgdir/usr/share/doc/sed"
}
