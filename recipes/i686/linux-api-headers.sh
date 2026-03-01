#!/bin/bash
set -euo pipefail

pkgname="linux-api-headers"
pkgver="6.12.65"
pkgrel=1
arch=("i686")
source=("https://linux-libre.fsfla.org/pub/linux-libre/releases/6.12.65-gnu/linux-libre-6.12.65-gnu.tar.xz")
sha256sums=("eb1af14e303c40de0b00fd869f392538ebd2055dd8dd4ec05c0ba3301a8eac14")
depends=()

makedepends=("bash" "coreutils" "gcc" "make")
description="linux api headers"

build() {
cd $srcdir

tar -xvf $srcdir/linux-libre-$pkgver-gnu.tar.xz
cd $srcdir/linux-$pkgver

local kernel_arch="i386"

make ARCH="${kernel_arch}" mrproper
make ARCH="${kernel_arch}" headers

find usr/include -type f ! -name '*.h' -delete
}

package() {
cd $srcdir/linux-$pkgver

mkdir -p "$pkgdir/usr"
cp -rv usr/include "$pkgdir/usr"
}
