#!/bin/bash
set -euo pipefail

pkgname="tcl"
pkgver="8.6.16"
pkgrel=1
arch=("i686")
source=("https://downloads.sourceforge.net/tcl/tcl8.6.16-src.tar.gz")
sha256sums=("91cb8fa61771c63c262efb553059b7c7ad6757afa5857af6265e4b0bdc2a14a5")
depends=("glibc" "zlib")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "glibc" "grep" "make" "sed")
description="tcl"

build() {
cd $srcdir
tar -xzf $srcdir/tcl$pkgver-src.tar.gz
cd $srcdir/tcl$pkgver

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath

make -j$(nproc)

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

if [ -f pkgs/tdbc1.1.10/tdbcConfig.sh ]; then
    sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.10/generic|/usr/include|"    \
        -e "s|$SRCDIR/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.10|/usr/include|"            \
        -i pkgs/tdbc1.1.10/tdbcConfig.sh
fi

if [ -f pkgs/itcl4.2.3/itclConfig.sh ]; then
    sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
        -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
        -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
        -i pkgs/itcl4.2.3/itclConfig.sh
fi

unset SRCDIR

}

package() {
cd $srcdir/tcl$pkgver/unix

make DESTDIR="$pkgdir" install

chmod 644 "$pkgdir/usr/lib/libtclstub8.6.a"

# Make the installed library writable so debugging symbols can be removed later
chmod -v u+w "$pkgdir/usr/lib/libtcl8.6.so"

# Install Tcl's headers. The next package, Expect, requires them
make DESTDIR="$pkgdir" install-private-headers

# Create a symlink named tclsh that points to the versioned tclsh8.6 executable
ln -sfv tclsh8.6 "$pkgdir/usr/bin/tclsh"

# Rename a man page that conflicts with a Perl man page
mv "$pkgdir/usr/share/man/man3/Thread.3" "$pkgdir/usr/share/man/man3/Tcl_Thread.3"
}
