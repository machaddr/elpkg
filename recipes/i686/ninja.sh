#!/bin/bash
set -euo pipefail

pkgname="ninja"
pkgver="1.13.1"
pkgrel=1
arch=("i686")
source=("https://github.com/ninja-build/ninja/archive/v1.13.1/ninja-1.13.1.tar.gz")
sha256sums=("f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23")
depends=("gcc" "glibc")

makedepends=("binutils" "coreutils" "gcc" "python")
description="ninja"

build() {
cd $srcdir
tar -xzf $srcdir/ninja-$pkgver.tar.gz
cd $srcdir/ninja-$pkgver

# When run, ninja normally utilizes the greatest possible number of processes in parallel.
# By default this is the number of cores on the system, plus two.
# This may overheat the CPU, or make the system run out of memory.
# When ninja is invoked from the command line, passing the -jN parameter will
# limit the number of parallel processes. Some packages embed the execution of ninja,
# and do not pass the -j parameter on to it.
# Using the optional procedure below allows a user to limit the number of parallel processes
# via an environment variable, NINJAJOBS. For example, setting
export NINJAJOBS=4

# If desired, make ninja recognize the environment variable NINJAJOBS by
# running the stream editor
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

# Build Ninja
python3 configure.py --bootstrap --verbose
}

package() {
cd $srcdir/ninja-$pkgver

mkdir -p "$pkgdir/usr/bin"
install -vm755 ninja "$pkgdir/usr/bin/ninja"
install -vDm644 misc/bash-completion "$pkgdir/usr/share/bash-completion/completions/ninja"
}
