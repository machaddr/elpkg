#!/bin/bash
set -euo pipefail

pkgname="gdbm"
pkgver="1.26"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/gdbm/gdbm-1.26.tar.gz")
sha256sums=("6a24504a14de4a744103dcb936be976df6fbe88ccff26065e54c1c47946f4a5e")
depends=("bash" "glibc" "readline")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "grep" "make" "sed")
description="gdbm"

build() {
cd $srcdir
tar -xzf $srcdir/gdbm-$pkgver.tar.gz
cd $srcdir/gdbm-$pkgver
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make -j$(nproc)
}

package() {
cd $srcdir/gdbm-$pkgver

make DESTDIR="$pkgdir" install
}
