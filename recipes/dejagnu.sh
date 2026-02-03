#!/bin/bash
set -euo pipefail

pkgname="dejagnu"
pkgver="1.6.3"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz")
sha256sums=("87daefacd7958b4a69f88c6856dbd1634261963c414079d0c371f589cd66a2e3")
depends=("expect" "bash")

makedepends=("bash" "coreutils" "diffutils" "expect" "gcc" "grep" "make" "sed" "texinfo")
description="dejagnu"

build() {
cd $srcdir
tar -xf $srcdir/dejagnu-$pkgver.tar.gz
cd $srcdir/dejagnu-$pkgver

mkdir -v $srcdir/dejagnu-$pkgver/build && \
    cd $srcdir/dejagnu-$pkgver/build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
}

package() {
cd $srcdir/dejagnu-$pkgver/build

make DESTDIR="$pkgdir" install

# Install documentation
install -v -dm755  $pkgdir/usr/share/doc/dejagnu
install -v -m644   doc/dejagnu.{html,txt} $pkgdir/usr/share/doc/dejagnu
}
