#!/bin/bash
set -euo pipefail

pkgname="vim"
pkgver="9.1.1629"
pkgrel=1
arch=("i686")
source=("https://github.com/vim/vim/archive/v9.1.1629/vim-9.1.1629.tar.gz")
sha256sums=("d92c6550e8eca741085fce94e5b0d3d13d2c62fcb5b69bf5a6010d3114de4828")
depends=("acl" "attr" "glibc" "python" "ncurses" "tcl")

makedepends=("acl" "attr" "bash" "binutils" "coreutils" "diffutils" "gcc" "glibc" "grep" "make" "ncurses" "sed")
description="vim"

build() {
srctop=$SRCDIR
cd "$srctop"
tar -xzf "$srctop/vim-$pkgver.tar.gz"
cd "$srctop/vim-$pkgver"

# Change the default location of the vimrc configuration file to /etc
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

unset SRCDIR
unset srcdir
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/vim-$pkgver
make DESTDIR="$pkgdir" install

# Many users reflexively type vi instead of vim. To allow execution of vim when users
# habitually enter vi, create a symlink for both the binary and the man page
# in the provided languages
ln -sv vim "$pkgdir/usr/bin/vi"
for L in "$pkgdir"/usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 "$(dirname "$L")/vi.1"
done
}

post_install() {
cat > /etc/vimrc << "EOF"
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
set number
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

EOF
}
