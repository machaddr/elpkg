#!/bin/bash
set -euo pipefail

pkgname="groff"
pkgver="1.23.0"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/groff/groff-1.23.0.tar.gz")
sha256sums=("6b9757f592b7518b4902eb6af7e54570bdccba37a871fddb2d30ae3863511c13")
depends=("gcc" "glibc" "perl")

makedepends=("bash" "binutils" "bison" "coreutils" "gawk" "gcc" "glibc" "grep" "make" "patch" "sed" "texinfo")
description="groff"

build() {
cd $srcdir
tar -xzf $srcdir/groff-$pkgver.tar.gz
cd $srcdir/groff-$pkgver
PAGE="A4" ./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/groff-$pkgver

make DESTDIR="$pkgdir" install
}
