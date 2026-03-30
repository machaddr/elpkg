#!/bin/bash
set -euo pipefail

pkgname="dhcpcd"
pkgver="10.3.0"
pkgrel=1
arch=("i686")
source=("https://github.com/NetworkConfiguration/dhcpcd/releases/download/v10.3.0/dhcpcd-10.3.0.tar.xz")
sha256sums=("06e4c1aaf958523f3fd1c57258c613c6c7ae56b8f1d678fa7943495d5ea6aeb5")
depends=("glibc" "systemd")

makedepends=("bash" "binutils" "coreutils" "gcc" "make")
description="dhcpcd"

build() {
cd $srcdir
tar -xf $srcdir/dhcpcd-$pkgver.tar.xz
cd $srcdir/dhcpcd-$pkgver

./configure --prefix=/usr            \
            --sysconfdir=/etc            \
            --libexecdir=/usr/lib/dhcpcd \
            --dbdir=/var/lib/dhcpcd      \
            --runstatedir=/run           \
            --disable-privsep
make
}

package() {
cd $srcdir/dhcpcd-$pkgver
make DESTDIR="$pkgdir" install
}
