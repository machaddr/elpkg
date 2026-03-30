#!/bin/bash
set -euo pipefail

pkgname="linux-api-headers"
pkgver="6.18.20"
pkgrel=1
arch=("x86_64")
source=("https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.20.tar.xz")
sha256sums=("837a5abd98e46078a0ae1400e2daad89ece45cc3209037b09c2265dab2393553")
depends=()

makedepends=("bash" "coreutils" "gcc" "make")
description="linux api headers"

build() {
cd $srcdir

tar -xvf $srcdir/linux-$pkgver.tar.xz
cd $srcdir/linux-$pkgver

local kernel_arch="x86_64"

make ARCH="${kernel_arch}" mrproper
make ARCH="${kernel_arch}" headers

find usr/include -type f ! -name '*.h' -delete
}

package() {
cd $srcdir/linux-$pkgver

mkdir -p "$pkgdir/usr"
cp -rv usr/include "$pkgdir/usr"
}
