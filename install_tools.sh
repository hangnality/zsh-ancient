#!/bin/bash
# =============================================================================
# Static binary installer for Linux x86_64
# fzf, ripgrep, fd, delta — all static/musl linked, no glibc dependency
# =============================================================================
set -euo pipefail

INSTALL_DIR="${1:-$HOME/.local/bin}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ---------------------------------------------------------------------------
# Versions (pinned)
# ---------------------------------------------------------------------------
FZF_VERSION="0.74.0"
RIPGREP_VERSION="15.1.0"
FD_VERSION="10.4.2"
DELTA_VERSION="0.19.2"

# ---------------------------------------------------------------------------
# URLs
# ---------------------------------------------------------------------------
FZF_URL="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
RIPGREP_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
FD_URL="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

download() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fSL -o "$dest" "$url"
  elif command -v wget &>/dev/null; then
    wget -q -O "$dest" "$url"
  else
    error "curl or wget required"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
mkdir -p "$INSTALL_DIR"

# --- fzf ---
info "Installing fzf ${FZF_VERSION} ..."
download "$FZF_URL" "$TMP_DIR/fzf.tar.gz"
tar xzf "$TMP_DIR/fzf.tar.gz" -C "$TMP_DIR"
install -m 755 "$TMP_DIR/fzf" "$INSTALL_DIR/fzf"

# --- ripgrep ---
info "Installing ripgrep ${RIPGREP_VERSION} ..."
download "$RIPGREP_URL" "$TMP_DIR/rg.tar.gz"
tar xzf "$TMP_DIR/rg.tar.gz" -C "$TMP_DIR"
install -m 755 "$TMP_DIR/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg" "$INSTALL_DIR/rg"

# --- fd ---
info "Installing fd ${FD_VERSION} ..."
download "$FD_URL" "$TMP_DIR/fd.tar.gz"
tar xzf "$TMP_DIR/fd.tar.gz" -C "$TMP_DIR"
install -m 755 "$TMP_DIR/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" "$INSTALL_DIR/fd"

# --- delta ---
info "Installing delta ${DELTA_VERSION} ..."
download "$DELTA_URL" "$TMP_DIR/delta.tar.gz"
tar xzf "$TMP_DIR/delta.tar.gz" -C "$TMP_DIR"
install -m 755 "$TMP_DIR/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta" "$INSTALL_DIR/delta"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
info "All tools installed to: $INSTALL_DIR"
echo ""
echo "  fzf     $(${INSTALL_DIR}/fzf --version)"
echo "  rg      $(${INSTALL_DIR}/rg --version | head -1)"
echo "  fd      $(${INSTALL_DIR}/fd --version)"
echo "  delta   $(${INSTALL_DIR}/delta --version)"
echo ""

if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo "Add to your ~/.zshrc.local:"
  echo ""
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
  echo ""
fi
