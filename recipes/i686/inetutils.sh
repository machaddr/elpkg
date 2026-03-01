#!/bin/bash
set -euo pipefail

pkgname="inetutils"
pkgver="2.6"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/inetutils/inetutils-2.6.tar.xz")
sha256sums=("68bedbfeaf73f7d86be2a7d99bcfbd4093d829f52770893919ae174c0b2357ca")
depends=("gcc" "glibc" "ncurses" "readline")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "grep" "make" "ncurses" "patch" "sed" "texinfo" "zlib")
description="inetutils"

build() {
cd $srcdir
tar -xf $srcdir/inetutils-$pkgver.tar.xz
cd $srcdir/inetutils-$pkgver

# First, make the package build with gcc-14.1 or later
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make -j$(nproc)
}

package() {
cd $srcdir/inetutils-$pkgver

make DESTDIR="$pkgdir" install

# Move a program to the proper location
mkdir -p "$pkgdir/usr/sbin"
mv -v "$pkgdir/usr/bin/ifconfig" "$pkgdir/usr/sbin/ifconfig"
}
