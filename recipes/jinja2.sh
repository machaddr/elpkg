#!/bin/bash
set -euo pipefail

pkgname="jinja2"
pkgver="3.1.6"
pkgrel=1
arch=("i686")
source=("https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.6.tar.gz")
sha256sums=("0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d")
depends=("markupsafe" "python")

makedepends=("markupsafe" "python" "setuptools" "wheel")
description="jinja2"

build() {
cd $srcdir
tar -xzf $srcdir/jinja2-$pkgver.tar.gz
cd $srcdir/jinja2-$pkgver
}

package() {
cd $srcdir/jinja2-$pkgver

# Build the package
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install the package
pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist Jinja2
}
