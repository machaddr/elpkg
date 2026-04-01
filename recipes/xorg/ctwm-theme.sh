#!/bin/bash
set -euo pipefail

pkgname="ctwm-theme"
pkgver="1.0"
pkgrel=7
arch=("x86_64" "i686")
source=(
    "https://www.ctwm.org/themes/neo-classic/neo-classic.tar.gz"
    "https://www.ctwm.org/themes/neo-classic/.ctwmrc"
)
sha256sums=(
    "b87a5a7541772b167dda5f0bdd71a2772ade9c38124dda9d2a107518b478c0a7"
    "64f52c0c46d343d0fb4ef7159c7af97de919cc888f6aabcfcbb0548c6e032a31"
)
depends=("ctwm" "xinit" "xorg-applications" "xorg-extra-apps" "xorg-fonts" "xterm")
makedepends=()
description="Neo-Classic CTWM session defaults for SomaLinux"

build() {
    cd "$srcdir"
    rm -rf neo-classic
    tar -xzf "$srcdir/neo-classic.tar.gz"
}

package() {
    cd "$srcdir/neo-classic"

    install -dm755 \
        "$pkgdir/etc/X11/ctwm" \
        "$pkgdir/etc/X11/xinit" \
        "$pkgdir/usr/share/ctwm/themes/neo-classic" \
        "$pkgdir/usr/share/doc/ctwm-theme"

    install -m644 \
        grey-iconify.xpm \
        grey-size.xpm \
        macfocus.xpm \
        "$pkgdir/usr/share/ctwm/themes/neo-classic/"

    # Keep the upstream Neo-Classic ctwmrc, but point pixmaps at the
    # packaged system location instead of a per-user home directory.
    sed 's|^PixmapDirectory ".*"|PixmapDirectory "/usr/share/ctwm/themes/neo-classic"|' \
        "$srcdir/.ctwmrc" > "$pkgdir/etc/X11/ctwm/system.ctwmrc"

    cat > "$pkgdir/etc/X11/xinit/xinitrc" <<'EOF_XINIT'
#!/bin/sh

xrdb="xrdb"
xmodmap="xmodmap"
xinitdir="/etc/X11/xinit"

userresources="$HOME/.Xresources"
usermodmap="$HOME/.Xmodmap"
sysresources="$xinitdir/.Xresources"
sysmodmap="$xinitdir/.Xmodmap"

if [ -f "$sysresources" ]; then
    if [ -x /usr/bin/cpp ]; then
        "$xrdb" -merge "$sysresources"
    else
        "$xrdb" -nocpp -merge "$sysresources"
    fi
fi

if [ -f "$sysmodmap" ]; then
    "$xmodmap" "$sysmodmap"
fi

if [ -f "$userresources" ]; then
    if [ -x /usr/bin/cpp ]; then
        "$xrdb" -merge "$userresources"
    else
        "$xrdb" -nocpp -merge "$userresources"
    fi
fi

if [ -f "$usermodmap" ]; then
    "$xmodmap" "$usermodmap"
fi

if [ -d "$xinitdir/xinitrc.d" ]; then
    for f in "$xinitdir/xinitrc.d"/?*.sh; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

xsetroot -solid DodgerBlue4 -cursor_name left_ptr

xterm -name login -ls -geometry 100x28+40+40 &

exec ctwm
EOF_XINIT
    chmod 755 "$pkgdir/etc/X11/xinit/xinitrc"
}
