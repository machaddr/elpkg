#!/bin/bash
set -euo pipefail

pkgname="attr"
pkgver="2.5.2"
pkgrel=1
arch=("i686")
source=("https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz")
sha256sums=("39bf67452fa41d0948c2197601053f48b3d78a029389734332a6309a680c6c87")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "grep" "m4" "make" "perl" "sed" "texinfo")
description="attr"

build() {
cd $srcdir
tar -xzf $srcdir/attr-$pkgver.tar.gz
cd $srcdir/attr-$pkgver
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr

make -j$(nproc)
}

package() {
cd $srcdir/attr-$pkgver

make DESTDIR="$pkgdir" install
}
