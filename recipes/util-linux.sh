#!/bin/bash
set -euo pipefail

pkgname="util-linux"
pkgver="2.41.1"
pkgrel=1
arch=("i686")
source=("https://www.kernel.org/pub/linux/utils/util-linux/v2.41/util-linux-2.41.1.tar.xz")
sha256sums=("be9ad9a276f4305ab7dd2f5225c8be1ff54352f565ff4dede9628c1aaa7dec57")
depends=("glibc" "ncurses" "readline" "systemd" "zlib")

makedepends=("bash" "binutils" "coreutils" "diffutils" "file" "findutils" "gawk" "gcc" "gettext" "glibc" "grep" "make" "ncurses" "pkgconf" "sed" "systemd" "zlib")
description="util linux"

build() {
cd $srcdir
tar -xf $srcdir/util-linux-$pkgver.tar.xz
cd $srcdir/util-linux-$pkgver

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --bindir=/usr/bin       \
            --libdir=/usr/lib       \
            --runstatedir=/run      \
            --sbindir=/usr/sbin     \
            --disable-chfn-chsh     \
            --disable-login         \
            --disable-nologin       \
            --disable-su            \
            --disable-setpriv       \
            --disable-runuser       \
            --disable-pylibmount    \
            --disable-liblastlog2   \
            --disable-static        \
            --without-python        \
            --docdir=/usr/share/doc/util-linux

make -j$(nproc)
}

package() {
cd $srcdir/util-linux-$pkgver
make DESTDIR="$pkgdir" install
}
