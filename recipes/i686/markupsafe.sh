#!/bin/bash
set -euo pipefail

pkgname="markupsafe"
pkgver="2.1.5"
pkgrel=1
arch=("i686")
source=("https://pypi.org/packages/source/M/MarkupSafe/MarkupSafe-2.1.5.tar.gz")
sha256sums=("d283d37a890ba4c1ae73ffadf8046435c76e7bc2247bbb63c00bd1a709c6544b")
depends=("python")

makedepends=("python" "setuptools" "wheel")
description="markupsafe"

build() {
cd $srcdir
tar -xzf $srcdir/MarkupSafe-$pkgver.tar.gz
cd $srcdir/MarkupSafe-$pkgver
}

package() {
cd $srcdir/MarkupSafe-$pkgver

# Build the package
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install the package
pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist MarkupSafe
}
