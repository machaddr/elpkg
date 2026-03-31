#!/bin/bash
set -euo pipefail

pkgname="libnl"
pkgver="3.12.0"
pkgrel=1
arch=("x86_64")
source=("https://github.com/thom311/libnl/releases/download/libnl${pkgver//./_}/libnl-$pkgver.tar.gz")
sha256sums=("fc51ca7196f1a3f5fdf6ffd3864b50f4f9c02333be28be4eeca057e103c0dd18")
depends=("glibc")
makedepends=("bash" "gcc" "make")
description="Netlink protocol library suite"

build() {
cd "$srcdir"
tar -xzf "$srcdir/libnl-$pkgver.tar.gz"
cd "$srcdir/libnl-$pkgver"

./configure --prefix=/usr \
            --sysconfdir=/etc \
            --disable-static

make
}

package() {
cd "$srcdir/libnl-$pkgver"

make DESTDIR="$pkgdir" install
rm -f "$pkgdir"/usr/lib/*.la
}
