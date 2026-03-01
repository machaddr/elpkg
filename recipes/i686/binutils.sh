#!/bin/bash
set -euo pipefail

pkgname="binutils"
pkgver="2.45"
pkgrel=1
arch=("i686")
source=("https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz")
sha256sums=("c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2")
depends=("glibc" "zlib" "zstd")

makedepends=("bash" "coreutils" "diffutils" "file" "flex" "gawk" "gcc" "glibc" "grep" "make" "perl" "pkgconf" "sed" "texinfo" "zlib" "zstd")
description="binutils"

build() {
cd $srcdir
tar -xf $srcdir/binutils-$pkgver.tar.xz
cd $srcdir/binutils-$pkgver

mkdir -v $srcdir/binutils-$pkgver/build && \
    cd $srcdir/binutils-$pkgver/build
../configure --prefix=/usr         \
             --build="$SOMALINUX_TGT" \
             --sysconfdir=/etc     \
             --enable-gold         \
             --enable-ld=default   \
             --enable-plugins      \
             --enable-shared       \
             --disable-werror      \
             --enable-64-bit-bfd   \
             --enable-new-dtags    \
             --with-system-zlib    \
             --enable-default-hash-style=gnu

make -j$(nproc) tooldir=/usr
}

package() {
cd $srcdir/binutils-$pkgver/build

make DESTDIR="$pkgdir" tooldir=/usr install

# Remove useless static libraries
rm -fv "$pkgdir/usr/lib/libbfd.a" \
       "$pkgdir/usr/lib/libctf.a" \
       "$pkgdir/usr/lib/libctf-nobfd.a" \
       "$pkgdir/usr/lib/libgprofng.a" \
       "$pkgdir/usr/lib/libopcodes.a" \
       "$pkgdir/usr/lib/libsframe.a"

# Remove gprofng docs if present
rm -rf "$pkgdir/usr/share/doc/gprofng"
}
