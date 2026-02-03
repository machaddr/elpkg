#!/bin/bash
set -euo pipefail

pkgname="acl"
pkgver="2.3.2"
pkgrel=1
arch=("i686")
source=("https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz")
sha256sums=("97203a72cae99ab89a067fe2210c1cbf052bc492b479eca7d226d9830883b0bd")
depends=("attr" "glibc")

makedepends=("attr" "bash" "binutils" "coreutils" "gcc" "gettext" "grep" "m4" "make" "perl" "sed" "texinfo")
description="acl"

build() {
cd $srcdir
tar -xf $srcdir/acl-$pkgver.tar.xz
cd $srcdir/acl-$pkgver
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl

make -j$(nproc)
}

package() {
cd $srcdir/acl-$pkgver

make DESTDIR="$pkgdir" install
}
