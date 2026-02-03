#!/bin/bash
set -euo pipefail

pkgname="libxcrypt"
pkgver="4.4.38"
pkgrel=1
arch=("i686")
source=("https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz")
sha256sums=("80304b9c306ea799327f01d9a7549bdb28317789182631f1b54f4511b4206dd6")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "make" "perl" "sed")
description="libxcrypt"

build() {
cd $srcdir
tar -xf $srcdir/libxcrypt-$pkgver.tar.xz
cd $srcdir/libxcrypt-$pkgver
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens

make -j$(nproc)
}

package() {
cd $srcdir/libxcrypt-$pkgver

make DESTDIR="$pkgdir" install
}
