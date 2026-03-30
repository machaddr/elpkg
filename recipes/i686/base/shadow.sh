#!/bin/bash
set -euo pipefail

pkgname="shadow"
pkgver="4.18.0"
pkgrel=1
arch=("i686")
source=("https://github.com/shadow-maint/shadow/releases/download/4.18.0/shadow-4.18.0.tar.xz")
sha256sums=("add4604d3bc410344433122a819ee4154b79dd8316a56298c60417e637c07608")
depends=("glibc" "libxcrypt")

makedepends=("acl" "attr" "bash" "binutils" "coreutils" "diffutils" "findutils" "gawk" "gcc" "gettext" "glibc" "grep" "libcap" "libxcrypt" "make" "sed")
description="shadow"

build() {
cd $srcdir
tar -xf $srcdir/shadow-$pkgver.tar.xz
cd $srcdir/shadow-$pkgver

# Disable the installation of the groups program and its man pages,
# as Coreutils provides a better version
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

# If you wish to include /bin and/or /sbin in the PATH for some reason,
# modify the PATH in .bashrc after SOMALINUX has been built
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32

make -j$(nproc)
}

package() {
cd $srcdir/shadow-$pkgver

make DESTDIR="$pkgdir" exec_prefix=/usr install
make DESTDIR="$pkgdir" -C man install-man
}
