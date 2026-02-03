#!/bin/bash
set -euo pipefail

pkgname="procps-ng"
pkgver="4.0.5"
pkgrel=1
arch=("i686")
source=("https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz")
sha256sums=("c2e6d193cc78f84cd6ddb72aaf6d5c6a9162f0470e5992092057f5ff518562fa")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make" "ncurses" "pkgconf" "systemd")
description="procps ng"

build() {
cd $srcdir
tar -xf $srcdir/procps-ng-$pkgver.tar.xz
cd $srcdir/procps-ng-$pkgver
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng       \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit                      \
            --with-systemd

make -j$(nproc)
}

package() {
cd $srcdir/procps-ng-$pkgver
make DESTDIR="$pkgdir" install
}
