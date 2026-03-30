#!/bin/bash
set -euo pipefail

pkgname="texinfo"
pkgver="7.2"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz")
sha256sums=("0329d7788fbef113fa82cb80889ca197a344ce0df7646fe000974c5d714363a6")
depends=("glibc" "ncurses")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "grep" "make" "ncurses" "patch" "sed")
description="texinfo"

build() {
cd $srcdir
tar -xf $srcdir/texinfo-$pkgver.tar.xz
cd $srcdir/texinfo-$pkgver

# Fix a code pattern that causes Perl-5.42 or later to display a warning
sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm

./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/texinfo-$pkgver
make DESTDIR="$pkgdir" install
# Optionally, install the components belonging in a TeX installation
make DESTDIR="$pkgdir" TEXMF=/usr/share/texmf install-tex
}

post_install() {
# Rebuild /usr/share/info/dir if present
if [ -d /usr/share/info ]; then
    pushd /usr/share/info
    rm -f dir
    for f in *; do
        install-info "$f" dir 2>/dev/null || true
    done
    popd
fi
}
