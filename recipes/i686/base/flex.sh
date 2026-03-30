#!/bin/bash
set -euo pipefail

pkgname="flex"
pkgver="2.6.4"
pkgrel=1
arch=("i686")
source=("https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz")
sha256sums=("e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995")
depends=("bash" "glibc" "m4")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "grep" "m4" "make" "patch" "sed" "texinfo")
description="flex"

build() {
cd $srcdir
tar -xzf $srcdir/flex-$pkgver.tar.gz
cd $srcdir/flex-$pkgver
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex \
            --disable-static

make -j$(nproc)
}

package() {
cd $srcdir/flex-$pkgver

make DESTDIR="$pkgdir" install

# Avoid packaging the global info dir file; it is owned by glibc.
rm -f "$pkgdir/usr/share/info/dir"

# A few programs do not know about flex yet and try to run its predecessor, lex.
# To support those programs, create a symbolic link named lex that runs flex in
# lex emulation mode, and also create the man page of lex as a symlink:
ln -sv flex   "$pkgdir/usr/bin/lex"
ln -sv flex.1 "$pkgdir/usr/share/man/man1/lex.1"
}
