#!/bin/bash
set -euo pipefail

pkgname="libfm"
pkgver="1.4.1"
pkgrel=3
arch=("x86_64" "i686")
source=("https://github.com/lxde/libfm/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("glib" "gtk2" "libfm-extra" "menu-cache")
makedepends=("autoconf" "automake" "gettext" "glib" "gtk2" "intltool" "libtool" "menu-cache" "pkgconf")
description="Core file management library used by PCManFM and LXPanel"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libfm-*' | head -n 1)"
    cd "$build_root"

    mkdir -p m4
    sed -i '/GTK_DOC_CHECK/{
s/.*/enable_gtk_doc=no/
a AM_CONDITIONAL([ENABLE_GTK_DOC], [false])
}' configure.ac
    cat > docs/reference/libfm/Makefile.am <<'EOF'
EXTRA_DIST = libfm-docs.xml libfm-sections.txt version.xml.in
DISTCLEANFILES = version.xml
test:
EOF
    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --with-gtk=2 \
        --disable-demo \
        --disable-exif \
        --disable-old-actions \
        --disable-udisks
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libfm-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install

    # Keep the bootstrap libfm-extra package as the owner of the extra library,
    # pkg-config file, and extra-only headers to avoid file ownership conflicts.
    rm -f \
        "$pkgdir/usr/include/libfm" \
        "$pkgdir/usr/include/libfm-1.0/fm-extra.h" \
        "$pkgdir/usr/include/libfm-1.0/fm-version.h" \
        "$pkgdir/usr/include/libfm-1.0/fm-xml-file.h" \
        "$pkgdir/usr/lib/libfm-extra.a" \
        "$pkgdir/usr/lib/libfm-extra.la" \
        "$pkgdir/usr/lib/libfm-extra.so" \
        "$pkgdir/usr/lib/pkgconfig/libfm-extra.pc"
    rm -f "$pkgdir"/usr/lib/libfm-extra.so.*
}
