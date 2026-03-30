#!/bin/bash
set -euo pipefail

pkgname="pyyaml"
pkgver="6.0.2"
pkgrel=1
arch=("x86_64" "i686")
source=("https://files.pythonhosted.org/packages/source/P/PyYAML/pyyaml-6.0.2.tar.gz")
sha256sums=("SKIP")
depends=("python")
makedepends=("python" "setuptools" "wheel")
description="YAML parser and emitter for Python"

build() {
    local archive="${source[0]##*/}"
    local srcroot="${archive%.tar.gz}"
    cd "$srcdir"
    tar -xf "$srcdir/$archive"
    cd "$srcdir/$srcroot"
}

package() {
    local archive="${source[0]##*/}"
    local srcroot="${archive%.tar.gz}"
    cd "$srcdir/$srcroot"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    pip3 install --root "$pkgdir" --prefix=/usr --ignore-installed --no-deps --no-index --find-links dist PyYAML
}
