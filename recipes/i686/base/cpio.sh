#!/bin/bash
set -euo pipefail

pkgname="cpio"
pkgver="2.15"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/cpio/cpio-2.15.tar.gz")
sha256sums=("efa50ef983137eefc0a02fdb51509d624b5e3295c980aa127ceee4183455499e")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "make" "sed")
description="cpio"

build() {
cd $srcdir

tar -xvf $srcdir/cpio-$pkgver.tar.gz
cd $srcdir/cpio-$pkgver

# Fix function prototypes for modern compilers (GCC 15+)
sed -e "/^extern int (\*xstat)/s/()/(const char * restrict,  struct stat * restrict)/"     -i src/extern.h
sed -e "/^int (\*xstat)/s/()/(const char * restrict,  struct stat * restrict)/"     -i src/global.c

./configure --prefix=/usr --enable-mt --with-rmt=/usr/libexec/rmt

make -j"$(nproc)"
}

package() {
cd $srcdir/cpio-$pkgver
make DESTDIR="$pkgdir" install
}
