#!/bin/bash
set -euo pipefail

pkgname="m4"
pkgver="1.4.20"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/m4/m4-1.4.20.tar.xz")
sha256sums=("e236ea3a1ccf5f6c270b1c4bb60726f371fa49459a8eaaebc90b216b328daf2b")
depends=("bash" "glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "grep" "make" "sed" "texinfo")
description="m4"

build() {
cd $srcdir
tar -xf $srcdir/m4-$pkgver.tar.xz
cd $srcdir/m4-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/m4-$pkgver

make DESTDIR="$pkgdir" install

# Avoid packaging the global info dir file; it is owned by glibc.
rm -f "$pkgdir/usr/share/info/dir"
}
