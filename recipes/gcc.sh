#!/bin/bash
set -euo pipefail

pkgname="gcc"
pkgver="15.2.0"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz")
sha256sums=("438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e")
depends=("bash" "binutils" "glibc" "mpc" "python")

makedepends=("bash" "binutils" "coreutils" "diffutils" "findutils" "gawk" "gettext" "glibc" "gmp" "grep" "m4" "make" "mpc" "mpfr" "patch" "perl" "sed" "tar" "texinfo" "zstd")
description="gcc"

build() {
cd $srcdir
tar -xf $srcdir/gcc-$pkgver.tar.xz
cd $srcdir/gcc-$pkgver

mkdir -v $srcdir/gcc-$pkgver/build && \
    cd $srcdir/gcc-$pkgver/build
../configure --prefix=/usr              \
             --build="$SOMALINUX_TGT"   \
             LD=ld                      \
             --enable-languages=c,c++   \
             --enable-default-pie       \
             --enable-default-ssp       \
             --enable-host-pie          \
             --disable-multilib         \
             --disable-bootstrap        \
             --disable-fixincludes      \
             --with-system-zlib

make -j$(nproc)
}

package() {
cd $srcdir/gcc-$pkgver/build

make DESTDIR="$pkgdir" install
}
