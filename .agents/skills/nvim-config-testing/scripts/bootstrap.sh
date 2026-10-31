#!/usr/bin/env bash
# Test the no-admin bootstrap (_bootstrap.sh / Makefile) without a full run.
#
#   bash bootstrap.sh WORK
#
#  1. Every download URL in pkgs/*.sh resolves, for both architectures.
#  2. No-argument call prints usage instead of crashing.
#  3. A dropped Neovim download (simulated by a fake wget that writes half a
#     file and exits 4) must fail the script and `make`, write no "installed"
#     marker, and a rerun with the real wget must then install cleanly.
#
# Simulate failures with a fake wget on PATH rather than by killing a real
# download: small downloads finish before you can interrupt them, and
# `pkill -f <pattern>` matches the shell running the pkill too.
# For a complete clean-machine bootstrap, build the bootstrap image instead:
#   bash images.sh WORK bootstrap
set -uo pipefail
WORK="$(cd "${1:?usage: bootstrap.sh WORK}" && pwd)"
B="$WORK/bootstrap"; rm -rf "$B"; cp -a "$WORK/src" "$B"; cd "$B" || exit 1

echo "== 1. download URLs"
for arch in aarch64 x86_64; do
  bash -c '
    PKG_DIR=/x; . ./pkgs/noarch.sh; . ./pkgs/'"$arch"'_linux.sh
    for u in "https://gnu.mirror.constant.com/stow/$STOW_PACKAGE.tar.gz" \
      "https://nodejs.org/download/release/v$NODE_VERSION/$NODE_PACKAGE.tar.gz" \
      "https://go.dev/dl/$GO_PACKAGE.tar.gz" \
      "https://ziglang.org/download/$ZIG_VERSION/$ZIG_PACKAGE.tar.xz" \
      "https://github.com/junikimm717/static-python/releases/download/python-$PYTHON_VERSION/$PYTHON_ARCHIVE.tar.gz" \
      "https://github.com/neovim/neovim/releases/download/v$NEOVIM_VERSION/$NEOVIM_DL.tar.gz" \
      "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/$RIPGREP_PACKAGE.tar.gz"; do
      echo "  '"$arch"' $(curl -sIL -o /dev/null -w "%{http_code}" "$u") $u"
    done'
done

echo "== 2. no argument"
out="$(./_bootstrap.sh 2>&1)"; echo "  exit=$? output: $out"

echo "== 3. dropped download"
mkdir -p "$WORK/fakebin"
cat > "$WORK/fakebin/wget" <<'EOF'
#!/bin/sh
# Fake wget: writes a truncated file to -O, then fails like a dropped connection.
out=""; while [ $# -gt 0 ]; do case "$1" in -O) out="$2"; shift;; esac; shift; done
[ -n "$out" ] && head -c 5000 /dev/urandom > "$out"
echo "fake wget: connection reset" >&2; exit 4
EOF
chmod +x "$WORK/fakebin/wget"
./_bootstrap.sh install_stow >/dev/null 2>&1 || echo "  (install_stow failed; needs network)"
PATH="$WORK/fakebin:$PATH" ./_bootstrap.sh install_neovim >/dev/null 2>&1
rc=$?; shopt -s nullglob; left=(build/pkgs/neovim*); shopt -u nullglob
echo "  script exit=$rc (want non-zero); left behind: ${left[*]:-nothing}"
mkdir -p build/installed; rm -f build/installed/neovim
PATH="$WORK/fakebin:$PATH" make build/installed/neovim >/dev/null 2>&1
echo "  make exit=$? (want non-zero); marker: $(ls build/installed/neovim 2>/dev/null || echo none)"
./_bootstrap.sh install_neovim >/dev/null 2>&1
echo "  rerun with real wget: exit=$?; $(./build/bin/nvim --version 2>&1 | head -1)"
