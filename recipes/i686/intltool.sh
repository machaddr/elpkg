#!/bin/bash
set -euo pipefail

pkgname="intltool"
pkgver="0.51.0"
pkgrel=1
arch=("i686")
source=("https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz")
sha256sums=("67c74d94196b153b774ab9f89b2fa6c6ba79352407037c8c14d5aeb334e959cd")
depends=("autoconf" "automake" "bash" "glibc" "grep" "perl" "sed")

makedepends=("bash" "gawk" "glibc" "make" "perl" "sed" "xml-parser")
description="intltool"

build() {
cd $srcdir
tar -xzf $srcdir/intltool-$pkgver.tar.gz
cd $srcdir/intltool-$pkgver

# First fix a warning that is caused by perl-5.22 and later
sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/intltool-$pkgver

make DESTDIR="$pkgdir" install
install -v -Dm644 doc/I18N-HOWTO "$pkgdir/usr/share/doc/intltool/I18N-HOWTO"
}
