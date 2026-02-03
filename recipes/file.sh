#!/bin/bash
set -euo pipefail

pkgname="file"
pkgver="5.46"
pkgrel=1
arch=("i686")
source=("https://astron.com/pub/file/file-5.46.tar.gz")
sha256sums=("c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088")
depends=("glibc" "bzip2" "xz" "zlib")

makedepends=("bash" "binutils" "bzip2" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "make" "sed" "xz" "zlib")
description="file"

build() {
cd $srcdir
tar -xzf $srcdir/file-$pkgver.tar.gz
cd $srcdir/file-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/file-$pkgver

make DESTDIR="$pkgdir" install
}
