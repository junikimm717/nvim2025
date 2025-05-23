#!/bin/sh

DIR="$(realpath "$(dirname "$0")")"
cd "$DIR" || exit 1

PKG_DIR="$DIR/build/pkgs"
BIN_DIR="$DIR/build/bin"
export PATH="$BIN_DIR:$PATH"

# Check os and architecture.
if test "$(uname -s)" != "Linux"; then
  echo "Neovim bootstrapping not supported! You must be on Linux"
  exit 1
fi

. ./pkgs/noarch.sh

case "$(arch)" in
  x86_64)
    . ./pkgs/x86_64_linux.sh
    ;;
  aarch64)
    . ./pkgs/aarch64_linux.sh
    ;;
  *)
    echo "Neovim bootstrapping not supported! You must be on aarch64 or x86_64"
    exit 1
    ;;
esac

nodeps=0
for cmd in git tar wget make perl unzip chmod tr awk; do
  if ! command -v $cmd > /dev/null 2>&1; then
    echo "You do not have $cmd! Cannot build..."
    nodeps=1
  fi
done
if test $nodeps -ne 0; then
  exit 1
fi

mkdir -p "$PKG_DIR"
mkdir -p "$BIN_DIR"

install_stow() {
  cd "$PKG_DIR" || exit 1
  if ! test -d "$STOW_PKG_PATH"; then
    echo "Stow not found, installing it..."

    ! test -f "$STOW_PACKAGE.tar.gz" &&\
      wget "https://ftp.gnu.org/gnu/stow/$STOW_PACKAGE.tar.gz"

    tar -xzf "$STOW_PACKAGE.tar.gz"
    cd "$STOW_PACKAGE" || exit 1
    ./configure && make
  fi
  cat <<EOF > "$BIN_DIR/stow" && chmod +x "$BIN_DIR/stow"
#!/bin/sh
DIR="\$(realpath "\$(dirname "\$0")")/../.."
PKG_DIR="\$DIR/build/pkgs"
BIN_DIR="\$DIR/build/bin"

perl -I"\$PKG_DIR/$STOW_PACKAGE/lib" "\$PKG_DIR/$STOW_PACKAGE/bin/stow" "\$@"
EOF
}

install_node() {
  cd "$PKG_DIR" || exit 1
  if ! test -d "$NODE_PKG_PATH"; then
    echo "Package not found, installing NodeJS version $NODE_VERSION..."
    ! test -f "$NODE_PACKAGE.tar.gz" &&\
      wget "https://nodejs.org/download/release/v$NODE_VERSION/$NODE_PACKAGE.tar.gz"
    tar -xzf "$NODE_PACKAGE.tar.gz"

    export PATH="$NODE_PKG_PATH/bin:$PATH"
    npm install -g tree-sitter-cli
  fi
  stow --target="$BIN_DIR" --stow --dir="$NODE_PACKAGE" bin
}

install_go() {
  cd "$PKG_DIR" || exit 1
  if ! test -d "$GO_PKG_PATH"; then
    echo "Package not found, installing Go version $GO_VERSION..."
      ! test -f $GO_PACKAGE.tar.gz &&\
        wget https://go.dev/dl/$GO_PACKAGE.tar.gz
      tar -xzf $GO_PACKAGE.tar.gz && mv go $GO_PACKAGE
      mkdir -p "$PKG_DIR/gopath"
  fi

  cat <<EOF > "$BIN_DIR/go" && chmod +x "$BIN_DIR/go"
#!/bin/sh
DIR="\$(realpath "\$(dirname "\$0")")/../.."
PKG_DIR="\$DIR/build/pkgs"
BIN_DIR="\$DIR/build/bin"
export GOBIN="\$BIN_DIR"
export GOPATH="\$PKG_DIR/gopath:\$GOPATH"
"\$PKG_DIR/$GO_PACKAGE/bin/go" "\$@"
EOF

  export GOBIN="$GO_PKG_PATH/bin"
  export GOPATH="$PKG_DIR/gopath"
  "$GO_PKG_PATH/bin/go" install golang.org/x/tools/gopls@latest

  cat <<EOF > "$BIN_DIR/gopls" && chmod +x "$BIN_DIR/gopls"
#!/bin/sh
DIR="\$(realpath "\$(dirname "\$0")")/../.."
PKG_DIR="\$DIR/build/pkgs"
BIN_DIR="\$DIR/build/bin"
export GOBIN="\$BIN_DIR"
export GOPATH="\$PKG_DIR/gopath:\$GOPATH"
"\$PKG_DIR/$GO_PACKAGE/bin/gopls" "\$@"
EOF
}

install_python() {
  # You need to force inclusion of venv for things to work as well.
  cd "$PKG_DIR" || exit 1
  if ! test -d "$PYTHON_PKG_PATH"; then
    echo "Package not found, installing Python3..."
    ! test -f "$PYTHON_PACKAGE.tar.gz" &&\
      wget "https://github.com/junikimm717/static-python/releases/download/binaries/$PYTHON_PACKAGE.tar.gz"
    tar -xzf "$PYTHON_PACKAGE.tar.gz"
    cd "$PYTHON_PACKAGE" || exit 1
  fi
  cd "$PKG_DIR" || exit 1
  stow --target="$DIR/build/bin" --stow --dir="$PYTHON_PACKAGE" bin
  mkdir -p "$DIR/build/lib" && stow --target="$DIR/build/lib" --stow --dir="$PYTHON_PACKAGE" lib
}

install_neovim() {
  cd "$PKG_DIR" || exit 1
  if ! test -d "$NEOVIM_PKG_PATH"; then
    echo "Package not found, installing Neovim version $NEOVIM_VERSION..."
    ! test -f "$NEOVIM_PACKAGE.tar.gz"\
      && wget "https://github.com/neovim/neovim/releases/download/v$NEOVIM_VERSION/$NEOVIM_DL.tar.gz"\
      && mv "$NEOVIM_DL.tar.gz" "$NEOVIM_PACKAGE.tar.gz"\
      && tar -xzf "$NEOVIM_PACKAGE.tar.gz"\
      && mv "$NEOVIM_DL" "$NEOVIM_PACKAGE"

    export PATH="$NEOVIM_PKG_PATH/bin:$PATH"
  fi
  # you need to write a "nvim" script that wraps everything with the correct
  # environment variables.
  mkdir -p "$DIR/build/nvim/config"
  rm -rf "$DIR/build/nvim/config/nvim"
  ln -sf "$DIR" "$DIR/build/nvim/config/nvim"
  cat <<EOF > "$BIN_DIR/nvim" && chmod +x "$BIN_DIR/nvim"
#!/bin/sh
DIR="\$(realpath "\$(dirname "\$0")")/../.."
PKG_DIR="\$DIR/build/pkgs"
BIN_DIR="\$DIR/build/bin"

export GOBIN="\$BIN_DIR"
export GOPATH="\$PKG_DIR/gopath:\$GOPATH"
export PATH="\$BIN_DIR:\$PATH"
export XDG_CONFIG_HOME="\$DIR/build/nvim/config"
export XDG_DATA_HOME="\$DIR/build/nvim/share"
if mkdir -p "\$DIR/build/nvim/state" 2>/dev/null && test -w "\$DIR/build/nvim/state"; then
  export XDG_STATE_HOME="\$DIR/build/nvim/state"
fi
if mkdir -p "\$DIR/build/nvim/cache" 2>/dev/null && test -w "\$DIR/build/nvim/cache"; then
  export XDG_CACHE_HOME="\$DIR/build/nvim/cache"
fi

"\$PKG_DIR/$NEOVIM_PACKAGE/bin/nvim" "\$@"
EOF
}

install_ripgrep() {
  cd "$PKG_DIR" || exit 1
  if ! test -d "$RIPGREP_PKG_PATH"; then
    echo "Package not found, installing Ripgrep version $RIPGREP_VERSION..."
    ! test -f $RIPGREP_PACKAGE.tar.gz &&\
      wget "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/$RIPGREP_PACKAGE.tar.gz" &&\
      tar -xzf "$RIPGREP_PACKAGE.tar.gz"
  fi
  cd "$PKG_DIR" || exit 1
  stow --target="$BIN_DIR" --stow --dir="$PKG_DIR" "$RIPGREP_PACKAGE"
}

install_tmuxs() {
  "$BIN_DIR/go" install github.com/junikimm717/tmuxs@latest
  "$BIN_DIR/go" install github.com/junegunn/fzf@latest
}

case "$1" in
  install_*)
    "$1"
    ;;
  *)
    echo "The bootstrapper should not be called directly."
    exit 1
    ;;
esac
