#!/bin/bash
set -euo pipefail

pkgname="readline"
pkgver="8.3"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/readline/readline-8.3.tar.gz")
sha256sums=("fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc")
depends=("glibc" "ncurses")

makedepends=("bash" "binutils" "coreutils" "gawk" "gcc" "glibc" "grep" "make" "ncurses" "patch" "sed" "texinfo")
description="readline"

build() {
cd $srcdir
tar -xzf $srcdir/readline-$pkgver.tar.gz
cd $srcdir/readline-$pkgver

# Reinstalling Readline will cause the old libraries to be moved
# to <libraryname>.old. While this is normally not a problem,
#in some cases it can trigger a linking bug in ldconfig.
# This can be avoided by issuing the following two seds
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline

make -j$(nproc) SHLIB_LIBS="-lncursesw"
}

package() {
cd $srcdir/readline-$pkgver

make DESTDIR="$pkgdir" install

# Avoid packaging the global info dir file; it is owned by glibc.
rm -f "$pkgdir/usr/share/info/dir"

# Install documentation
mkdir -p "$pkgdir/usr/share/doc/readline"
install -v -m644 doc/*.{ps,pdf,html,dvi} "$pkgdir/usr/share/doc/readline"
}
