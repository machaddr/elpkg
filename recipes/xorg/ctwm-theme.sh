#!/bin/bash
set -euo pipefail

pkgname="ctwm-theme"
pkgver="1.0"
pkgrel=5
arch=("x86_64" "i686")
source=("https://www.ctwm.org/themes/neo-classic/neo-classic.tar.gz")
sha256sums=("b87a5a7541772b167dda5f0bdd71a2772ade9c38124dda9d2a107518b478c0a7")
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
        "$pkgdir/root" \
        "$pkgdir/usr/share/ctwm/themes/neo-classic" \
        "$pkgdir/usr/share/doc/ctwm-theme"

    install -m644 \
        grey-iconify.xpm \
        grey-size.xpm \
        macfocus.xpm \
        "$pkgdir/usr/share/ctwm/themes/neo-classic/"

    cat > "$pkgdir/etc/X11/ctwm/somalinux-neo-classic.ctwmrc" <<'EOF_CTWM'
# -*- shell-script -*-

NoDefaults

PixmapDirectory "/usr/share/ctwm/themes/neo-classic"

Color
{
    BorderColor           "grey65"
    BorderTileBackground  "black"
    DefaultBackground     "grey65"
    DefaultForeground     "black"
    TitleBackground       "grey70"
    TitleForeground       "black"
    MenuBackground        "grey70"
    MenuForeground        "black"
    MenuTitleBackground   "grey40"
    MenuTitleForeground   "black"
    IconManagerBackground "grey90"
    IconManagerForeground "black"
    IconManagerHighlight  "black"
}

Cursors
{
    Frame   "top_left_arrow"
    Title   "top_left_arrow"
    Icon    "box_spiral"
    IconMgr "top_left_arrow"
    Move    "fleur"
    Resize  "sizing"
    Menu    "sb_left_arrow"
    Button  "hand2"
    Wait    "watch"
    Select  "dot"
    Destroy "pirate"
}

Pixmaps
{
    TitleHighlight "xpm:macfocus.xpm"
}

TitleFont "-*-helvetica-medium-r-*-*-10-*-*-*-p-*-*-*"
MenuFont "-*-helvetica-medium-r-*-*-10-*-*-*-p-*-*-*"
WorkspaceFont "-*-helvetica-medium-r-*-*-8-*-*-*-*-*-*-*"

ShowWorkSpaceManager
UsePPosition "on"
WarpCursor
WorkSpaceManagerGeometry "190x22-0-0" 6
StartInMapState

DontPaintRootWindow

WorkSpaces
{
    "1" { "grey60" "black" "grey60" "black" }
    "2" { "grey60" "black" "grey60" "black" }
    "3" { "grey60" "black" "grey60" "black" }
    "4" { "grey60" "black" "grey60" "black" }
    "5" { "grey60" "black" "grey60" "black" }
    "6" { "grey60" "black" "grey60" "black" }
}

OccupyAll
{
    "swisswatch"
    "xwatch"
}

NoShowOccupyAll

UseThreeDMenus

ButtonIndent 0
TitleButtonBorderWidth 0

FramePadding 2
NoGrabServer
NoHighLight
NoRaiseOnMove
RestartPreviousState
DecorateTransients
BorderWidth 1
IconifyByUnmapping

Notitle
{
    ""
    "rclock"
    "swisswatch"
    "TWM Icon Manager"
    "WorkSpaceManager"
    "xbiff"
    "xphone"
    "Dali Clock"
}

IconManagerDontShow
{
    "TWM Icon Manager"
    "X DeskTop Manager"
    "xclock"
    "rclock"
    "xbiff"
    "xload"
}

DontIconifyByUnmapping
{
    "xclock"
    "rclock"
    "xbiff"
    "xload"
    "Dali Clock"
    "Untitled"
}

MoveDelta 3
Function "move-or-lower" { f.move f.deltastop f.lower }
Function "move-or-raise" { f.move f.deltastop f.raise }
Function "move-or-iconify" { f.move f.deltastop f.iconify }

LeftTitleButton "xpm:grey-iconify.xpm" = f.iconify
RightTitleButton "xpm:grey-size.xpm" = f.resize

Button1 = : root : f.menu "defops"
Button2 = : root : f.menu "programs"
Button3 = : root : f.menu "programs"

Button1 = m : window|icon : f.function "move-or-lower"
Button2 = m : window|icon : f.iconify
Button3 = m : window|icon : f.function "move-or-raise"

Button1 = : title : f.function "move-or-raise"
Button2 = : title : f.raiselower

Button1 = : icon : f.function "move-or-iconify"
Button2 = : icon : f.iconify

Button1 = : iconmgr : f.iconify
Button2 = : iconmgr : f.iconify

menu "defops"
{
    "Twm"          f.title
    "Iconify"      f.iconify
    "Resize"       f.resize
    "Move"         f.move
    "Raise"        f.raise
    "Lower"        f.lower
    ""             f.nop
    "Focus"        f.focus
    "Unfocus"      f.unfocus
    "Show Iconmgr" f.showiconmgr
    "Hide Iconmgr" f.hideiconmgr
    ""             f.nop
    "Kill"         f.destroy
    "Delete"       f.delete
    ""             f.nop
    "Restart"      f.restart
    "Exit"         f.quit
}

menu "programs"
{
    "Xorg Applications"  f.title
    "XTerm"              f.exec "xterm -ls &"
    "Classic X Extras"   f.menu "extra-apps"
    ""                   f.nop
    "Current X Clients"  f.exec "xterm -T 'X Clients' -e sh -lc \"xlsclients; printf '\\nPress Enter to close...'; read _\" &"
    "Display Info"       f.exec "xterm -T 'Display Info' -e sh -lc \"xdpyinfo; printf '\\nPress Enter to close...'; read _\" &"
    "Display Modes"      f.exec "xterm -T 'Display Modes' -e sh -lc \"xrandr --query; printf '\\nPress Enter to close...'; read _\" &"
    "Window Info"        f.exec "xwininfo &"
    "Window Properties"  f.exec "xprop &"
    "Event Tester"       f.exec "xev &"
    "Kill Window"        f.exec "xkill &"
    "Message Box"        f.exec "xmessage 'SomaLinux CTWM is running.' &"
}

menu "extra-apps"
{
    "Xorg Extra Applications" f.title
    "Calculator"             f.exec "xcalc &"
    "Console"                f.exec "xconsole &"
    "Text Editor"            f.exec "xedit &"
    "XEyes"                  f.exec "xeyes &"
    "Load Monitor"           f.exec "xload &"
    "Magnifier"              f.exec "xmag &"
    "Ico Demo"               f.exec "ico &"
    "Bitmap Editor"          f.exec "bitmap &"
    "Clock"                  f.exec "oclock &"
    "Mail Checker"           f.exec "xbiff &"
}
EOF_CTWM
    ln -sf somalinux-neo-classic.ctwmrc "$pkgdir/etc/X11/ctwm/system.ctwmrc"

    cat > "$pkgdir/etc/X11/xinit/xinitrc.somalinux-neo-classic" <<'EOF_XINIT'
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
    chmod 755 "$pkgdir/etc/X11/xinit/xinitrc.somalinux-neo-classic"
    ln -sf xinitrc.somalinux-neo-classic "$pkgdir/etc/X11/xinit/xinitrc"

    cat > "$pkgdir/root/.xinitrc" <<'EOF_ROOT_XINITRC'
#!/bin/sh
exec /etc/X11/xinit/xinitrc
EOF_ROOT_XINITRC
    chmod 755 "$pkgdir/root/.xinitrc"

    cat > "$pkgdir/root/.bash_profile" <<'EOF_BASH_PROFILE'
if [ -z "${DISPLAY:-}" ] && [ -r /proc/cmdline ] && [ -x /usr/bin/startx ]; then
    case " $(cat /proc/cmdline) " in
        *" somalinux.mode=graphical "*)
            if [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; then
                startx
            fi
            ;;
    esac
fi
EOF_BASH_PROFILE

    cat > "$pkgdir/usr/share/doc/ctwm-theme/README" <<'EOF_README'
SomaLinux ships the upstream Neo-Classic ctwm session profile as the
system-wide default.

Start the desktop with:
  startx

Graphical boot entry:
  boot "SomaLinux Graphical Mode" from GRUB

Installed defaults:
  /etc/X11/ctwm/system.ctwmrc
  /etc/X11/ctwm/somalinux-neo-classic.ctwmrc
  /etc/X11/xinit/xinitrc
  /etc/X11/xinit/xinitrc.somalinux-neo-classic
  /usr/share/ctwm/themes/neo-classic
  /root/.xinitrc
  /root/.bash_profile
EOF_README
}
