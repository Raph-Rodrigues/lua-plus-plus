# Maintainer: Raph-Rodrigues <raph.edits06@gmail.com>
#
# Lua++ (Arch Linux package)
#
# The release workflow replaces 'sha256sums' with the checksum of the
# GitHub tag tarball.  When building locally from a clean checkout you can
# either use the PKGBUILD published in the release assets or run
# 'makepkg --skipchecksums' (the tarball is downloaded from the tagged
# release, so it is still pinned to that tag).

pkgname=lua++
pkgver=5.5.1
pkgrel=1
pkgdesc="Lua++: experimental fork of Lua 5.5 with optional typing, ++, compound assignments and mandatory semicolons"
arch=('x86_64')
url="https://github.com/Raph-Rodrigues/lua-plus-plus"
license=('MIT')
depends=('glibc')
makedepends=('make' 'gcc')
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

_srcname=lua-plus-plus

build() {
  cd "$srcdir/$_srcname-$pkgver"
  make -j"$(nproc)"
}

check() {
  cd "$srcdir/$_srcname-$pkgver"
  ./src/lua++ test_luaplusplus.lua
}

package() {
  cd "$srcdir/$_srcname-$pkgver"
  install -Dm755 src/lua++ "$pkgdir/usr/bin/lua++"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
