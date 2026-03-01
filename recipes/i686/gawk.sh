#!/bin/bash
set -euo pipefail

pkgname="gawk"
pkgver="5.3.2"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz")
sha256sums=("f8c3486509de705192138b00ef2c00bbbdd0e84c30d5c07d23fc73a9dc4cc9cc")
depends=("bash" "glibc" "mpfr")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "gmp" "grep" "make" "mpfr" "patch" "readline" "sed" "texinfo")
description="gawk"

build() {
cd $srcdir
tar -xf $srcdir/gawk-$pkgver.tar.xz
cd $srcdir/gawk-$pkgver

# Ensure some unneeded files are not installed
sed -i 's/extras//' Makefile.in

./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/gawk-$pkgver

rm -f "$pkgdir/usr/bin/gawk-$pkgver"
make DESTDIR="$pkgdir" install

# The installation process already created awk as a symlink to gawk,
# create its man page as a symlink as well
ln -sv gawk.1 "$pkgdir/usr/share/man/man1/awk.1"

# Install documentation
mkdir -pv                                   "$pkgdir/usr/share/doc/gawk"
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} "$pkgdir/usr/share/doc/gawk"
}
