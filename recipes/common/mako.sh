#!/bin/bash
set -euo pipefail

pkgname="mako"
pkgver="1.3.10"
pkgrel=1
arch=("x86_64" "i686")
source=("https://files.pythonhosted.org/packages/source/M/Mako/mako-1.3.10.tar.gz")
sha256sums=("SKIP")
depends=("markupsafe" "python")
makedepends=("markupsafe" "python" "setuptools" "wheel")
description="Python templating engine"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/mako-$pkgver.tar.gz"
    cd "$srcdir/mako-$pkgver"
}

package() {
    cd "$srcdir/mako-$pkgver"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist Mako
}
