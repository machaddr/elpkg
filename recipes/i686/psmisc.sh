#!/bin/bash
set -euo pipefail

pkgname="psmisc"
pkgver="23.7"
pkgrel=1
arch=("i686")
source=("https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz")
sha256sums=("58c55d9c1402474065adae669511c191de374b0871eec781239ab400b907c327")
depends=("glibc" "ncurses")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "grep" "make" "ncurses" "sed")
description="psmisc"

build() {
cd $srcdir
tar -xf $srcdir/psmisc-$pkgver.tar.xz
cd $srcdir/psmisc-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/psmisc-$pkgver

make DESTDIR="$pkgdir" install
}
