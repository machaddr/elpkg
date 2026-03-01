#!/bin/bash
set -euo pipefail

pkgname="pkgconf"
pkgver="2.5.1"
pkgrel=1
arch=("i686")
source=("https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz")
sha256sums=("cd05c9589b9f86ecf044c10a2269822bc9eb001eced2582cfffd658b0a50c243")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gawk" "gcc" "glibc" "grep" "make" "sed")
description="pkgconf"

build() {
cd $srcdir
tar -xf $srcdir/pkgconf-$pkgver.tar.xz
cd $srcdir/pkgconf-$pkgver

./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf

make -j$(nproc)
}

package() {
cd $srcdir/pkgconf-$pkgver

make DESTDIR="$pkgdir" install

# To maintain compatibility with the original Pkg-config create two symlinks
ln -sv pkgconf   "$pkgdir/usr/bin/pkg-config"
ln -sv pkgconf.1 "$pkgdir/usr/share/man/man1/pkg-config.1"
}
