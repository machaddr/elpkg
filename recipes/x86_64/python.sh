#!/bin/bash
set -euo pipefail

pkgname="python"
pkgver="3.13.7"
pkgrel=1
arch=("x86_64")
source=("https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz")
sha256sums=("5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a")
depends=("bzip2" "expat" "gdbm" "glibc" "libffi" "libxcrypt" "ncurses" "openssl" "zlib")

makedepends=("bash" "binutils" "coreutils" "expat" "gcc" "gdbm" "gettext" "glibc" "grep" "libffi" "libxcrypt" "make" "ncurses" "openssl" "pkgconf" "sed" "util-linux")
description="python"

configure_python_runtime_libpath() {
    local paths=()
    [[ -d /usr/lib64 ]] && paths+=("/usr/lib64")
    [[ -d /usr/lib ]] && paths+=("/usr/lib")
    if [[ ${#paths[@]} -gt 0 ]]; then
        export LD_LIBRARY_PATH="$(IFS=:; echo "${paths[*]}")${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
}

build() {
cd $srcdir
tar -xf $srcdir/Python-$pkgver.tar.xz
cd $srcdir/Python-$pkgver
configure_python_runtime_libpath
./configure --prefix=/usr           \
            --enable-shared         \
            --with-system-expat     \
            --enable-optimizations  \
            --without-static-libpython

make -j$(nproc)
}

package() {
cd $srcdir/Python-$pkgver
configure_python_runtime_libpath

make DESTDIR="$pkgdir" install

mkdir -p "$pkgdir/etc"
cat > "$pkgdir/etc/pip.conf" << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
}
