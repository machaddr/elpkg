#!/bin/bash
set -euo pipefail

pkgname="iana-etc"
pkgver="20250807"
pkgrel=1
arch=("i686")
source=("https://github.com/Mic92/iana-etc/releases/download/20250807/iana-etc-20250807.tar.gz")
sha256sums=("4f88470a2cac2a2f9568285aaff9aeaee0ab66c6ba3c12bba51adca915fa92b1")
depends=()

makedepends=("coreutils")
description="iana etc"

build() {
cd $srcdir
tar -xzf $srcdir/iana-etc-$pkgver.tar.gz
cd $srcdir/iana-etc-$pkgver
}

package() {
cd $srcdir/iana-etc-$pkgver

mkdir -p "$pkgdir/etc"
cp services protocols "$pkgdir/etc"
}
