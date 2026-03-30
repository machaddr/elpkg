#!/bin/bash
set -euo pipefail

pkgname="perl"
pkgver="5.42.0"
pkgrel=1
arch=("i686")
source=("https://www.cpan.org/src/5.0/perl-5.42.0.tar.xz")
sha256sums=("73cf6cc1ea2b2b1c110a18c14bbbc73a362073003893ffcedc26d22ebdbdd0c3")
depends=("gdbm" "glibc" "libxcrypt")

makedepends=("bash" "binutils" "coreutils" "gawk" "gcc" "gdbm" "glibc" "grep" "libxcrypt" "make" "sed" "zlib")
description="perl"

build() {
cd $srcdir
tar -xf $srcdir/perl-$pkgver.tar.xz
cd $srcdir/perl-$pkgver

# This version of Perl builds the Compress::Raw::Zlib and Compress::Raw::BZip2 modules.
# By default Perl will use an internal copy of the sources for the build.
# Issue the following command so that Perl will use the libraries installed on the system
export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                       \
             -Dprefix=/usr                              \
             -Dvendorprefix=/usr                        \
             -Dprivlib=/usr/lib/perl5/core_perl         \
             -Darchlib=/usr/lib/perl5/core_perl         \
             -Dsitelib=/usr/lib/perl5/site_perl         \
             -Dsitearch=/usr/lib/perl5/site_perl        \
             -Dvendorlib=/usr/lib/perl5/vendor_perl     \
             -Dvendorarch=/usr/lib/perl5/vendor_perl    \
             -Dman1dir=/usr/share/man/man1              \
             -Dman3dir=/usr/share/man/man3              \
             -Dpager="/usr/bin/less -isR"               \
             -Duseshrplib                               \
             -Dusethreads

make -j$(nproc)
}

package() {
cd $srcdir/perl-$pkgver

make DESTDIR="$pkgdir" install
}

post_install() {
unset BUILD_ZLIB BUILD_BZIP2
}
