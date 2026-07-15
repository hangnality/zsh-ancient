#!/bin/bash
# =============================================================================
# Source build installer for Linux x86_64
# Builds ncurses, libevent, tmux, vim into ~/.local with no root required
# Works with GCC 4.4+ on systems as old as CentOS 6
# =============================================================================
set -euo pipefail

PREFIX="${1:-$HOME/.local}"
JOBS=$(nproc 2>/dev/null || echo 2)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ---------------------------------------------------------------------------
# Versions (pinned)
# ---------------------------------------------------------------------------
NCURSES_VERSION="6.6"
LIBEVENT_VERSION="2.0.22-stable"
TMUX_VERSION="3.7b"
VIM_VERSION="9.2.0782"

# ---------------------------------------------------------------------------
# URLs
# ---------------------------------------------------------------------------
NCURSES_URL="https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
LIBEVENT_URL="https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz"
TMUX_URL="https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

download() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fSL -o "$dest" "$url"
  elif command -v wget &>/dev/null; then
    wget -q -O "$dest" "$url"
  else
    error "curl or wget required"
  fi
}

# ---------------------------------------------------------------------------
# ncurses (dependency for tmux and vim)
# ---------------------------------------------------------------------------
info "Building ncurses ${NCURSES_VERSION} ..."
download "$NCURSES_URL" "$TMP_DIR/ncurses.tar.gz"
tar xzf "$TMP_DIR/ncurses.tar.gz" -C "$TMP_DIR"
cd "$TMP_DIR/ncurses-${NCURSES_VERSION}"
./configure --prefix="$PREFIX" --with-shared --with-termlib --enable-pc-files \
  --with-pkg-config-libdir="$PREFIX/lib/pkgconfig" --without-debug --without-ada \
  --enable-widec
make -j"$JOBS"
make install
# Symlink ncursesw headers into $PREFIX/include so tools find termcap.h etc.
ln -sfn "$PREFIX/include/ncursesw"/*.h "$PREFIX/include/"
# Symlink libncursesw as libncurses for tools that look for -lncurses
ln -sf "$PREFIX/lib/libncursesw.so" "$PREFIX/lib/libncurses.so"
ln -sf "$PREFIX/lib/libncursesw.a" "$PREFIX/lib/libncurses.a"
cd /

# ---------------------------------------------------------------------------
# libevent (dependency for tmux)
# ---------------------------------------------------------------------------
info "Building libevent ${LIBEVENT_VERSION} ..."
download "$LIBEVENT_URL" "$TMP_DIR/libevent.tar.gz"
tar xzf "$TMP_DIR/libevent.tar.gz" -C "$TMP_DIR"
cd "$TMP_DIR/libevent-${LIBEVENT_VERSION}"
./configure --prefix="$PREFIX"
make -j"$JOBS"
make install
cd /

# ---------------------------------------------------------------------------
# tmux
# ---------------------------------------------------------------------------
info "Building tmux ${TMUX_VERSION} ..."
download "$TMUX_URL" "$TMP_DIR/tmux.tar.gz"
tar xzf "$TMP_DIR/tmux.tar.gz" -C "$TMP_DIR"
cd "$TMP_DIR/tmux-${TMUX_VERSION}"
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
CFLAGS="-I$PREFIX/include -I$PREFIX/include/ncurses" \
LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib" \
./configure --prefix="$PREFIX"
make -j"$JOBS"
make install
cd /

# ---------------------------------------------------------------------------
# vim
# ---------------------------------------------------------------------------
info "Building vim ${VIM_VERSION} ..."
download "https://github.com/vim/vim/archive/refs/tags/v${VIM_VERSION}.tar.gz" "$TMP_DIR/vim.tar.gz"
tar xzf "$TMP_DIR/vim.tar.gz" -C "$TMP_DIR"
cd "$TMP_DIR/vim-${VIM_VERSION}"
export C_INCLUDE_PATH="$PREFIX/include"
export LIBRARY_PATH="$PREFIX/lib"
CFLAGS="-I$PREFIX/include" \
LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -ltinfow -lrt" \
./configure --prefix="$PREFIX" --with-features=huge --enable-multibyte --without-x \
  --with-tlib=ncursesw
make -j"$JOBS"
make install
unset C_INCLUDE_PATH LIBRARY_PATH
cd /


# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
info "All tools installed to: $PREFIX"
echo ""
echo "  ncurses   ${NCURSES_VERSION}"
echo "  libevent  ${LIBEVENT_VERSION}"
echo "  tmux      $($PREFIX/bin/tmux -V)"
echo "  vim       $($PREFIX/bin/vim --version | head -1)"
echo ""

if [[ ":$PATH:" != *":${PREFIX}/bin:"* ]]; then
  echo "Add to your ~/.zshrc.local:"
  echo ""
  echo "  export PATH=\"$PREFIX/bin:\$PATH\""
  echo "  export LD_LIBRARY_PATH=\"$PREFIX/lib:\${LD_LIBRARY_PATH:-}\""
  echo ""
fi
