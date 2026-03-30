#!/bin/bash
set -euo pipefail

pkgname="netbsd-ctwm-theme"
pkgver="1.0"
pkgrel=1
arch=("x86_64" "i686")
source=()
sha256sums=()
depends=("ctwm" "xclock" "xinit" "xorg-applications" "xorg-extra-apps" "xorg-fonts" "xterm")
makedepends=()
description="NetBSD-inspired CTWM session defaults for SomaLinux"

build() {
    :
}

package() {
    install -dm755 \
        "$pkgdir/etc/X11/ctwm" \
        "$pkgdir/etc/X11/Xresources" \
        "$pkgdir/etc/X11/xinit" \
        "$pkgdir/root" \
        "$pkgdir/usr/libexec/somalinux" \
        "$pkgdir/usr/share/doc/netbsd-ctwm-theme"

    cat > "$pkgdir/usr/libexec/somalinux/ctwm_app_menu" <<'EOF_SCRIPT'
#!/bin/sh
set -eu

app_dirs=""
for dir in /usr/share/applications /usr/local/share/applications "${HOME:-}/.local/share/applications"; do
    if [ -d "$dir" ]; then
        app_dirs="$app_dirs $dir"
    fi
done

[ -n "$app_dirs" ] || exit 0

find $app_dirs -name '*.desktop' -exec awk -F= '
    function resetentry() {
        name = menu = exec = ""
        terminal = nodisplay = 0
    }
    function quote(s) {
        gsub(/\\/, "\\\\", s)
        gsub(/\"/, "\\\"", s)
        gsub(/\t/, "\\t", s)
        return "\"" s "\""
    }
    function printentry() {
        if (nodisplay || !name || !exec) {
            return
        }
        if (terminal) {
            exec = "xterm -class UXTerm -e " exec
        }
        if (!menu) {
            menu = "Misc"
        }
        printf "%02d\t%s\t%s\t%s\n", menuorder[menu], quote(menu), quote(" " name), "!" quote(exec " &")
    }
    function iskey(k) { return $1 == k }
    function value(v) { v = $0; sub(/^[^=]*=/, "", v); return v }

    BEGIN {
        menuno = 0
        menuorder["Accessories"] = menuno++
        menuorder["Games"] = menuno++
        menuorder["Graphics"] = menuno++
        menuorder["Internet"] = menuno++
        menuorder["Multimedia"] = menuno++
        menuorder["Office"] = menuno++
        menuorder["Programming"] = menuno++
        menuorder["System"] = menuno++
        menuorder["Misc"] = menuno++
        for (menu in menuorder) {
            printf "%02d\t%s\n", menuorder[menu], quote(menu)
        }

        catmenu["Audio"] = "Multimedia"
        catmenu["Development"] = "Programming"
        catmenu["Game"] = "Games"
        catmenu["Graphics"] = "Graphics"
        catmenu["Network"] = "Internet"
        catmenu["Office"] = "Office"
        catmenu["System"] = "System"
        catmenu["Utility"] = "Accessories"

        catno = 0
        catorder[catno++] = "Audio"
        catorder[catno++] = "Development"
        catorder[catno++] = "Graphics"
        catorder[catno++] = "Game"
        catorder[catno++] = "Office"
        catorder[catno++] = "Network"
        catorder[catno++] = "System"
        catorder[catno++] = "Utility"

        resetentry()
    }

                    { gsub(/\r/, "") }
    FNR == 1 && NR > 1 { printentry() }
    END             { printentry() }
    FNR == 1        { resetentry() }

    iskey("Name") && !name      { name = value() }
    /^Terminal=true$/           { terminal = 1 }
    iskey("OnlyShowIn")         { nodisplay = 1 }
    /^NoDisplay=true$/          { nodisplay = 1 }
    iskey("Exec") && !exec      {
        exec = value()
        gsub(/ %.*/, "", exec)
        if (exec ~ /\"/) {
            nodisplay = 1
        }
    }
    iskey("Categories") && !menu {
        categories = value()
        for (i = 0; i < catno; i++) {
            if (categories ~ catorder[i]) {
                menu = catmenu[catorder[i]]
                break
            }
        }
    }
' '{}' + |
sort -u |
awk -F '\t' '
    function startmenu(menu) {
        printf "menu %s\n", menu
        printf "{\n"
        printf "\t%s\tf.title\n", menu
        curmenu = menu
    }
    function endmenu() {
        if (curmenu) {
            printf "}\n"
        }
    }

    $2 != curmenu { endmenu(); startmenu($2) }
    NF == 4       { printf "\t%s %s \n", $3, $4 }
    END           { endmenu() }
'
EOF_SCRIPT
    chmod 755 "$pkgdir/usr/libexec/somalinux/ctwm_app_menu"

    cat > "$pkgdir/etc/X11/ctwm/somalinux-netbsd.ctwmrc" <<'EOF_CTWM'
NoDefaults

DontShowWelcomeWindow
ShowWorkSpaceManager
ShowIconManager
UseThreeDBorders
UseThreeDTitles

TitleFont       "9x15bold"
MenuFont        "9x15"
IconManagerFont "9x15"
IconFont        "9x15"
ResizeFont      "9x15"
WorkSpaceFont   "9x15bold"

WorkSpaceManagerGeometry "70x250-4-4" 1
IconManagerGeometry      "240x-1-1+0" 1
BorderWidth              3
ThreeDBorderWidth        3

RestartPreviousState
DecorateTransients
DontPaintRootWindow
NoOpaqueMove
NoOpaqueResize
AutoRelativeResize
CenterFeedbackWindow
NoGrabServer
RaiseOnClick
DontMoveOff
MoveOffResistance 150
ConstrainedMoveTime 0
IgnoreLockModifier
RandomPlacement "on"
ClearShadowContrast 40
DarkShadowContrast 60
StayUpMenus
WarpToDefaultMenuEntry
MenuShadowDepth 1
WindowRing
WarpRingOnScreen
NoTitleHighlight
TitleButtonShadowDepth 1
TitleShadowDepth 1
TitleButtonBorderWidth 0
TitlePadding 0
TitleJustification "left"
ButtonIndent 0
FramePadding 0
BorderShadowDepth 2
BorderResizeCursors
MaxIconTitleWidth 160
NoIconManagerFocus
IconManagerShadowDepth 1
IconifyByUnmapping
ReallyMoveInWorkspaceManager
MapWindowCurrentWorkSpace { "black" "darkorange3" }
DontToggleWorkSpaceManagerState
DontWarpCursorInWMap
NoShowOccupyAll
ReverseCurrentWorkspace
StartInMapState
WMgrHorizButtonIndent 0
WMgrVertButtonIndent 0

LeftTitleButton  ":xpm:dot"    = f.menu "titleops"
RightTitleButton ":xpm:resize" = f.resize
RightTitleButton ":xpm:cross"  = f.delete

WorkSpaces
{
    "1" { "lavender" "black" "darkslateblue" "white" }
    "2" { "lavender" "black" "darkslateblue" "white" }
    "3" { "lavender" "black" "darkslateblue" "white" }
    "4" { "lavender" "black" "darkslateblue" "white" }
    "5" { "lavender" "black" "darkslateblue" "white" }
}

Cursors
{
    Frame   "left_ptr"
    Title   "left_ptr"
    Icon    "left_ptr"
    IconMgr "left_ptr"
    Move    "fleur"
    Resize  "fleur"
    Menu    "left_ptr"
    Button  "hand2"
    Wait    "watch"
    Select  "dot"
    Destroy "pirate"
}

Color
{
    BorderColor           "black"
    BorderTileBackground  "darkslateblue"
    BorderTileForeground  "darkslateblue"
    DefaultBackground     "lavender"
    DefaultForeground     "black"
    TitleBackground       "lavender"
    TitleForeground       "black"
    MenuBackground        "lavender"
    MenuForeground        "black"
    MenuTitleBackground   "darkorange3"
    MenuTitleForeground   "black"
    MenuShadowColor       "gray15"
    IconBackground        "lavender"
    IconForeground        "black"
    IconBorderColor       "darkslateblue"
    IconManagerBackground "lavender"
    IconManagerForeground "black"
    IconManagerHighlight  "firebrick"
    MapWindowBackground   "lavender"
    MapWindowForeground   "black"
}

esyscmd(/usr/libexec/somalinux/ctwm_app_menu)

menu "appmenu"
{
    "Applications" f.title
    " Accessories" f.menu "Accessories"
    " Games"       f.menu "Games"
    " Graphics"    f.menu "Graphics"
    " Internet"    f.menu "Internet"
    " Multimedia"  f.menu "Multimedia"
    " Office"      f.menu "Office"
    " Programming" f.menu "Programming"
    " System"      f.menu "System"
    " Misc"        f.menu "Misc"
}

menu "deskutils"
{
    "Desktop utilities" f.title
    " Calculator"       !"xcalc &"
    " Text editor"      !"xedit &"
    ""                  f.separator
    " XEyes"            !"xeyes &"
    " XConsole"         !"xconsole &"
    " Magnify"          !"xmag -source 100x100 &"
    " Bitmap editor"    !"bitmap &"
    " Kill window"      !"xkill &"
}

menu "termutils"
{
    "Terminal utilities" f.title
    " Terminal"          !"uxterm &"
    " XTerm"             !"xterm &"
    " Top processes"     !"xterm -class UXTerm -e top &"
    " Editor"            !"xterm -class UXTerm -e vi &"
}

menu "SomaLinux"
{
    "SomaLinux"          f.title
    ""                   f.separator
    " Terminal"          !"uxterm &"
    " Clock"             !"xclock &"
    ""                   f.separator
    " Applications"      f.menu "appmenu"
    " Desktop utilities" f.menu "deskutils"
    " Terminal utilities" f.menu "termutils"
    ""                   f.separator
    " Restart CTWM"      f.twmrc
    " Quit"              f.quit
}

menu "titleops"
{
    "Window"      f.title
    ""            f.separator
    " Iconify"    f.iconify
    " Resize"     f.resize
    " Move"       f.move
    ""            f.separator
    " Occupy ..." f.occupy
    " Occupy All" f.occupyall
    ""            f.separator
    " Raise"      f.raise
    " Lower"      f.lower
    ""            f.separator
    " Zoom"       f.fullzoom
    " Zoom-V"     f.zoom
    " Zoom-H"     f.horizoom
    ""            f.separator
    " Stick"      f.stick
    " Close"      f.delete
}

Function "raise-move"       { f.raise f.deltastop f.forcemove }
Function "raise-and-resize" { f.raise f.deltastop f.resize }

Button1 = : root          : f.menu "SomaLinux"
Button2 = : root          : f.menu "TwmAllWindows"
Button3 = : root          : f.menu "SomaLinux"
Button1 = : title          : f.function "raise-move"
Button2 = : title          : f.function "raise-and-resize"
Button3 = : title | frame : f.menu "titleops"
Button1 = : frame          : f.function "raise-and-resize"
Button1 = : icon | iconmgr : f.iconify
Button2 = : icon           : f.move
Button3 = : icon | iconmgr : f.raiselower

"space" = mod1 : window : f.menu "titleops"
"p"     = mod1 : all    : f.menu "SomaLinux"
EOF_CTWM

    ln -sf somalinux-netbsd.ctwmrc "$pkgdir/etc/X11/ctwm/system.ctwmrc"

    cat > "$pkgdir/etc/X11/Xresources/somalinux-netbsd" <<'EOF_XRES'
XTerm*background: black
XTerm*foreground: white
XTerm*cursorColor: goldenrod
XTerm*saveLines: 4096
XTerm*scrollBar: false
XTerm*rightScrollBar: false
XTerm*borderWidth: 1
XTerm*VT100*font: 9x15
UXTerm*background: black
UXTerm*foreground: white
UXTerm*cursorColor: goldenrod
UXTerm*saveLines: 4096
UXTerm*scrollBar: false
UXTerm*rightScrollBar: false
UXTerm*borderWidth: 1
UXTerm*VT100*font: 9x15
EOF_XRES

    cat > "$pkgdir/etc/X11/xinit/xinitrc" <<'EOF_XINIT'
#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/Xresources/somalinux-netbsd
xinitdir=/etc/X11/xinit/xinitrc.d

[ -f "$sysresources" ] && xrdb -merge "$sysresources"
[ -f "$userresources" ] && xrdb -merge "$userresources"
[ -f "$usermodmap" ] && xmodmap "$usermodmap"

if [ -d "$xinitdir" ]; then
    for script in "$xinitdir"/*.sh; do
        [ -x "$script" ] && . "$script"
    done
fi

xsetroot -solid '#51459a' -cursor_name left_ptr
xset b off

exec ctwm
EOF_XINIT
    chmod 755 "$pkgdir/etc/X11/xinit/xinitrc"

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

    cat > "$pkgdir/usr/share/doc/netbsd-ctwm-theme/README" <<'EOF_README'
SomaLinux ships a NetBSD-inspired ctwm session profile.

Start the desktop with:
  startx

Graphical boot entry:
  boot "SomaLinux Graphical Mode" from GRUB

Installed defaults:
  /etc/X11/ctwm/system.ctwmrc
  /etc/X11/Xresources/somalinux-netbsd
  /etc/X11/xinit/xinitrc
  /root/.bash_profile
EOF_README
}
