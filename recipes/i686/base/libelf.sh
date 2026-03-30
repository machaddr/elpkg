#!/bin/bash
set -euo pipefail

pkgname="libelf"
pkgver="0.193"
pkgrel=1
arch=("i686")
source=("https://sourceware.org/ftp/elfutils/0.193/elfutils-0.193.tar.bz2")
sha256sums=("7857f44b624f4d8d421df851aaae7b1402cfe6bcdd2d8049f15fc07d3dde7635")
depends=("bzip2" "glibc" "xz" "zlib" "zstd")

makedepends=("bash" "binutils" "bzip2" "coreutils" "gcc" "glibc" "make" "xz" "zlib" "zstd")
description="libelf"

build() {
cd $srcdir
tar -xjf $srcdir/elfutils-$pkgver.tar.bz2
cd $srcdir/elfutils-$pkgver
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy

make -j$(nproc)
}

package() {
cd $srcdir/elfutils-$pkgver

make DESTDIR="$pkgdir" -C libelf install
mkdir -p "$pkgdir/usr/lib/pkgconfig"
install -vm644 config/libelf.pc "$pkgdir/usr/lib/pkgconfig/libelf.pc"
rm -v "$pkgdir/usr/lib/libelf.a"
}
