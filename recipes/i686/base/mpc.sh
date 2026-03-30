#!/bin/bash
set -euo pipefail

pkgname="mpc"
pkgver="1.3.1"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz")
sha256sums=("ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8")
depends=("glibc" "gmp" "mpfr")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "gmp" "make" "mpfr" "sed" "texinfo")
description="mpc"

build() {
cd $srcdir
tar -xzf $srcdir/mpc-$pkgver.tar.gz
cd $srcdir/mpc-$pkgver
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc

make -j$(nproc)
make -j$(nproc) html
}

package() {
cd $srcdir/mpc-$pkgver

make DESTDIR="$pkgdir" install
make DESTDIR="$pkgdir" install-html
}
