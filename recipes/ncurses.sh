#!/bin/bash
set -euo pipefail

pkgname="ncurses"
pkgver="6.5-20250809"
pkgrel=1
arch=("i686")
source=("https://invisible-mirror.net/archives/ncurses/current/ncurses-6.5-20250809.tgz")
sha256sums=("b071468b8c79099a378ed9bea937a605509f71e720402e2541abe20ad753c555")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "make" "patch" "sed")
description="ncurses"

build() {
cd $srcdir
tar -xzf $srcdir/ncurses-$pkgver.tgz
cd $srcdir/ncurses-$pkgver
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make -j$(nproc)
}

package() {
cd $srcdir/ncurses-$pkgver

make DESTDIR="$pkgdir" install

sed -e 's/^#if.*XOPEN.*$/#if 1/' \
  -i "$pkgdir/usr/include/curses.h"

# Many applications still expect the linker to be able to find
# non-wide-character Ncurses libraries. Trick such applications
# into linking with wide-character libraries by means of symlinks and linker scripts
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so "$pkgdir/usr/lib/lib${lib}.so"
    ln -sfv ${lib}w.pc "$pkgdir/usr/lib/pkgconfig/${lib}.pc"
done

ln -sfv libncursesw.so "$pkgdir/usr/lib/libcurses.so"

# Install the Ncurses documentation
mkdir -p "$pkgdir/usr/share/doc"
cp -v -R doc -T "$pkgdir/usr/share/doc/ncurses"
}
