#!/bin/bash
set -euo pipefail

pkgname="gettext"
pkgver="0.26"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/gettext/gettext-0.26.tar.xz")
sha256sums=("d1fb86e260cfe7da6031f94d2e44c0da55903dbae0a2fa0fae78c91ae1b56f00")
depends=("acl" "bash" "gcc" "glibc")

makedepends=("bash" "binutils" "coreutils" "gawk" "gcc" "glibc" "grep" "make" "ncurses" "sed" "texinfo")
description="gettext"

build() {
cd $srcdir
tar -xf $srcdir/gettext-$pkgver.tar.xz
cd $srcdir/gettext-$pkgver
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext

make -j$(nproc)
}

package() {
cd $srcdir/gettext-$pkgver

make DESTDIR="$pkgdir" install
chmod -v 0755 "$pkgdir/usr/lib/preloadable_libintl.so"
}
