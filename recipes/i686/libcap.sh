#!/bin/bash
set -euo pipefail

pkgname="libcap"
pkgver="2.76"
pkgrel=1
arch=("i686")
source=("https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.76.tar.xz")
sha256sums=("629da4ab29900d0f7fcc36227073743119925fd711c99a1689bbf5c9b40c8e6f")
depends=("glibc")

makedepends=("attr" "bash" "binutils" "coreutils" "gcc" "glibc" "perl" "make" "sed")
description="libcap"

build() {
cd $srcdir
tar -xf $srcdir/libcap-$pkgver.tar.xz
cd $srcdir/libcap-$pkgver

# Prevent static libraries from being installed
sed -i '/install -m.*STA/d' libcap/Makefile

make -j$(nproc) prefix=/usr lib=lib
}

package() {
cd $srcdir/libcap-$pkgver

make DESTDIR="$pkgdir" prefix=/usr lib=lib install
}
