#!/bin/bash
set -euo pipefail

pkgname="man-db"
pkgver="2.13.1"
pkgrel=1
arch=("i686")
source=("https://download.savannah.gnu.org/releases/man-db/man-db-2.13.1.tar.xz")
sha256sums=("8afebb6f7eb6bb8542929458841f5c7e6f240e30c86358c1fbcefbea076c87d9")
depends=("bash" "gdbm" "groff" "glibc" "gzip" "less" "libpipeline" "zlib")

makedepends=("bash" "binutils" "bzip2" "coreutils" "flex" "gcc" "gdbm" "gettext" "glibc" "grep" "groff" "gzip" "less" "libpipeline" "make" "pkgconf" "sed" "systemd" "xz")
description="man db"

build() {
cd $srcdir
tar -xf $srcdir/man-db-$pkgver.tar.xz
cd $srcdir/man-db-$pkgver
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/man-db      \
            --sysconfdir=/etc                   \
            --disable-setuid                    \
            --enable-cache-owner=bin            \
            --with-browser=/usr/bin/lynx        \
            --with-vgrind=/usr/bin/vgrind       \
            --with-grap=/usr/bin/grap

make -j$(nproc)
}

package() {
cd $srcdir/man-db-$pkgver
make DESTDIR="$pkgdir" install
}
