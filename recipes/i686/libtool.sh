#!/bin/bash
set -euo pipefail

pkgname="libtool"
pkgver="2.5.4"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz")
sha256sums=("f81f5860666b0bc7d84baddefa60d1cb9fa6fceb2398cc3baca6afaa60266675")
depends=("autoconf" "automake" "bash" "binutils" "coreutils" "file" "gcc" "glibc" "grep" "make" "sed")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "make" "sed" "texinfo")
description="libtool"

build() {
cd $srcdir
tar -xf $srcdir/libtool-$pkgver.tar.xz
cd $srcdir/libtool-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/libtool-$pkgver

make DESTDIR="$pkgdir" install

# Remove a useless static library
rm -fv "$pkgdir/usr/lib/libltdl.a"
}
