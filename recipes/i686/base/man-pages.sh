#!/bin/bash
set -euo pipefail

pkgname="man-pages"
pkgver="6.15"
pkgrel=1
arch=("i686")
source=("https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.15.tar.xz")
sha256sums=("03d8ebf618bd5df57cb4bf355efa3f4cd3a00b771efd623d4fd042b5dceb4465")
depends=()

makedepends=("bash" "coreutils" "make" "sed")
description="man pages"

build() {
cd $srcdir
tar -xf $srcdir/man-pages-"$pkgver".tar.xz
cd $srcdir/man-pages-"$pkgver"

rm -v man3/crypt*
}

package() {
cd $srcdir/man-pages-"$pkgver"

make DESTDIR="$pkgdir" -R GIT=false prefix=/usr install
}
