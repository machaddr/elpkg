#!/bin/bash
set -euo pipefail

pkgname="kmod"
pkgver="34.2"
pkgrel=1
arch=("i686")
source=("https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz")
sha256sums=("5a5d5073070cc7e0c7a7a3c6ec2a0e1780850c8b47b3e3892226b93ffcb9cb54")
depends=("glibc" "xz" "zlib")

makedepends=("bash" "binutils" "bison" "coreutils" "flex" "gcc" "gettext" "glibc" "gzip" "make" "openssl" "pkgconf" "sed" "xz" "zlib")
description="kmod"

build() {
cd $srcdir
tar -xf $srcdir/kmod-$pkgver.tar.xz
cd $srcdir/kmod-$pkgver

mkdir -v $srcdir/kmod-$pkgver/build && \
    cd $srcdir/kmod-$pkgver/build

meson setup --prefix=/usr ..    \
            --buildtype=release \
            -D manpages=false

ninja
}

package() {
cd $srcdir/kmod-$pkgver/build

DESTDIR="$pkgdir" ninja install
}
