#!/bin/bash
set -euo pipefail

pkgname="iwd"
pkgver="3.12"
pkgrel=1
arch=("x86_64")
source=("https://www.kernel.org/pub/linux/network/wireless/iwd-$pkgver.tar.xz")
sha256sums=("d89a5e45c7180170e19be828f9e944a768c593758094fc57a358d0e7c4cb1a49")
depends=("d-bus" "glibc" "readline" "systemd")
makedepends=("bash" "gcc" "make" "pkgconf" "d-bus" "readline" "systemd")
description="Intel wireless daemon"

build() {
cd "$srcdir"
tar -xf "$srcdir/iwd-$pkgver.tar.xz"
cd "$srcdir/iwd-$pkgver"

./configure --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var \
            --libexecdir=/usr/libexec

make -j"$(nproc)"
}

package() {
cd "$srcdir/iwd-$pkgver"
make DESTDIR="$pkgdir" install
}
