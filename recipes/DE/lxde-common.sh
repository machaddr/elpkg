#!/bin/bash
set -euo pipefail

pkgname="lxde-common"
pkgver="0.99.3"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxde-common/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gpicview" "leafpad" "lxappearance" "lxappearance-obconf" "lxde-icon-theme" "lxhotkey" "lxinput" "lxlauncher" "lxmenu-data" "lxmusic" "lxpanel" "lxrandr" "lxsession" "lxtask" "lxterminal" "openbox" "pcmanfm" "xinit")
makedepends=("autoconf" "automake" "gettext" "intltool")
description="Default configuration and session files for LXDE"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxde-common-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxde-common-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install

    install -dm755 "$pkgdir/etc/X11/xinit/xinitrc.d"
    cat > "$pkgdir/etc/X11/xinit/xinitrc.d/99-lxde.sh" <<'EOF_XINIT'
#!/bin/sh

exec startlxde
EOF_XINIT
    chmod 755 "$pkgdir/etc/X11/xinit/xinitrc.d/99-lxde.sh"
}
