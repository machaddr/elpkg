#!/bin/bash
set -euo pipefail

pkgname="iproute2"
pkgver="6.16.0"
pkgrel=1
arch=("i686")
source=("https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.16.0.tar.xz")
sha256sums=("5900ccc15f9ac3bf7b7eae81deb5937123df35e99347a7f11a22818482f0a8d0")
depends=("bash" "coreutils" "glibc" "libcap" "libelf" "zlib")

makedepends=("bash" "bison" "coreutils" "flex" "gcc" "glibc" "make" "libcap" "libelf" "linux-api-headers" "pkgconf" "zlib")
description="iproute2"

build() {
cd $srcdir
tar -xf $srcdir/iproute2-$pkgver.tar.xz
cd $srcdir/iproute2-$pkgver

# The arpd program included in this package will not be built
# since it depends on Berkeley DB
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

make -j$(nproc) NETNS_RUN_DIR=/run/netns
}

package() {
cd $srcdir/iproute2-$pkgver

make DESTDIR="$pkgdir" SBINDIR=/usr/sbin install

# Install documentation
mkdir -pv "$pkgdir/usr/share/doc/iproute2"
install -vDm644 COPYING README* -t "$pkgdir/usr/share/doc/iproute2"
}
