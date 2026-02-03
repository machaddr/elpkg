#!/bin/bash
set -euo pipefail

pkgname="grep"
pkgver="3.12"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/grep/grep-3.12.tar.xz")
sha256sums=("2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "gettext" "glibc" "make" "patch" "sed" "texinfo")
description="grep"

build() {
cd $srcdir
tar -xf $srcdir/grep-$pkgver.tar.xz
cd $srcdir/grep-$pkgver

# Remove a warning about using egrep and fgrep that
# makes tests on some packages fail
sed -i "s/echo/#echo/" src/egrep.sh

./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/grep-$pkgver

make DESTDIR="$pkgdir" install
}
