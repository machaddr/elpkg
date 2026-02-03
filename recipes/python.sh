#!/bin/bash
set -euo pipefail

pkgname="python"
pkgver="3.13.7"
pkgrel=1
arch=("i686")
source=("https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz")
sha256sums=("5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a")
depends=("bzip2" "expat" "gdbm" "glibc" "libffi" "libxcrypt" "ncurses" "openssl" "zlib")

makedepends=("bash" "binutils" "coreutils" "expat" "gcc" "gdbm" "gettext" "glibc" "grep" "libffi" "libxcrypt" "make" "ncurses" "openssl" "pkgconf" "sed" "util-linux")
description="python"

build() {
cd $srcdir
tar -xf $srcdir/Python-$pkgver.tar.xz
cd $srcdir/Python-$pkgver
./configure --prefix=/usr           \
            --enable-shared         \
            --with-system-expat     \
            --enable-optimizations  \
            --without-static-libpython

make -j$(nproc)
}

package() {
cd $srcdir/Python-$pkgver

make DESTDIR="$pkgdir" install

mkdir -p "$pkgdir/etc"
cat > "$pkgdir/etc/pip.conf" << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
}
