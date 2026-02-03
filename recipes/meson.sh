#!/bin/bash
set -euo pipefail

pkgname="meson"
pkgver="1.8.3"
pkgrel=1
arch=("i686")
source=("https://github.com/mesonbuild/meson/releases/download/1.8.3/meson-1.8.3.tar.gz")
sha256sums=("f118aa910fc0a137cc2dd0122232dbf82153d9a12fb5b0f5bb64896f6a157abf")
depends=("python")

makedepends=("ninja" "python" "setuptools" "wheel")
description="meson"

build() {
cd $srcdir
tar -xzf $srcdir/meson-$pkgver.tar.gz
cd $srcdir/meson-$pkgver
}

package() {
cd $srcdir/meson-$pkgver

# Compile Meson with the following command
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install the package
pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson "$pkgdir/usr/share/bash-completion/completions/meson"
}
