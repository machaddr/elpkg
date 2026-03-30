#!/bin/bash
set -euo pipefail

pkgname="libnl"
pkgver="3.2.25"
pkgrel=1
arch=("x86_64")
source=("https://www.infradead.org/~tgr/libnl/files/libnl-$pkgver.tar.gz")
sha256sums=("8beb7590674957b931de6b7f81c530b85dc7c1ad8fbda015398bc1e8d1ce8ec5")
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

make -j"$(nproc)"
}

package() {
cd "$srcdir/libnl-$pkgver"

make DESTDIR="$pkgdir" install
rm -f "$pkgdir"/usr/lib/*.la
}
