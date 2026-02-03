#!/bin/bash
set -euo pipefail

pkgname="bash"
pkgver="5.3"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/bash/bash-5.3.tar.gz")
sha256sums=("0d5cd86965f869a26cf64f4b71be7b96f90a3ba8b3d74e27e8e9d9d5550f31ba")
depends=("glibc" "ncurses" "readline")

makedepends=("binutils" "bison" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "make" "ncurses" "patch" "readline" "sed" "texinfo")
description="bash"

build() {
cd $srcdir
tar -xf $srcdir/bash-$pkgver.tar.gz
cd $srcdir/bash-$pkgver
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash

make -j$(nproc)
}

package() {
cd $srcdir/bash-$pkgver

make DESTDIR="$pkgdir" install
}
