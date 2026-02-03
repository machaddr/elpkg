#!/bin/bash
set -euo pipefail

pkgname="expect"
pkgver="5.45.4"
pkgrel=1
arch=("i686")
source=("https://downloads.sourceforge.net/project/expect/Expect/5.45.4/expect5.45.4.tar.gz")
sha256sums=("49a7da83b0bdd9f46d04a04deec19c7767bb9a323e40c4781f89caf760b92c34")
depends=("glibc" "tcl")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "glibc" "grep" "make" "patch" "sed" "tcl")
description="expect"

build() {
cd $srcdir
tar -xzf $srcdir/expect$pkgver.tar.gz
cd $srcdir/expect$pkgver

python3 -c 'from pty import spawn; spawn(["echo", "ok"])'

patch -Np1 -i $patchdir/expect-5.45.4-gcc15-1.patch

./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make -j$(nproc)
}

package() {
cd $srcdir/expect$pkgver

make DESTDIR="$pkgdir" install

# Create a symlink for the shared library
ln -svf expect$pkgver/libexpect$pkgver.so "$pkgdir/usr/lib"
}
