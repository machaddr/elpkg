#!/bin/bash
set -euo pipefail

pkgname="gmp"
pkgver="6.3.0"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz")
sha256sums=("a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898")
depends=("gcc" "glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "m4" "make" "sed" "texinfo")
description="gmp"

build() {
cd $srcdir
tar -xf $srcdir/gmp-$pkgver.tar.xz
cd $srcdir/gmp-$pkgver

# Make an adjustment for compatibility with gcc-15 and later
sed -i '/long long t1;/,+1s/()/(...)/' configure

ABI=32 ./configure --prefix=/usr    \
            --enable-cxx            \
            --disable-static        \
            --docdir=/usr/share/doc/gmp

make -j$(nproc)
make -j$(nproc) html
}

package() {
cd $srcdir/gmp-$pkgver

make DESTDIR="$pkgdir" install
make DESTDIR="$pkgdir" install-html
}
