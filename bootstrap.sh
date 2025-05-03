#!/bin/sh

# This is a bootstrapping script meant for setting up dev environments on hpc
# clusters for personal use. As a result, it only supports x86_64 at the moment.

# This script assumes existence of the following tools:
# 1. basic build tools (gcc, etc), not including cmake
# 2. perl

# If a package is installed, all the script does it make sure the symlinks are
# set correctly.

DIR="$(realpath "$(dirname "$0")")"
PKG_DIR="$DIR/build/pkgs"
BIN_DIR="$DIR/build/bin"
export PATH="$BIN_DIR:$PATH"

# Config variables for versions and paths.

STOW_VERSION="2.4.1"
STOW_PACKAGE="stow-$STOW_VERSION"
STOW_PKG_PATH="$PKG_DIR/$STOW_PACKAGE"

NODE_VERSION="23.11.0"
NODE_PACKAGE="node-v$NODE_VERSION-linux-x64"
NODE_PKG_PATH="$PKG_DIR/$NODE_PACKAGE"

PYTHON_VERSION="3.13.3"
PYTHON_PACKAGE="Python-$PYTHON_VERSION"
PYTHON_PKG_PATH="$PKG_DIR/$PYTHON_PACKAGE"

GETTEXT_VERSION="0.24"
GETTEXT_PACKAGE="gettext-$GETTEXT_VERSION"
GETTEXT_PKG_PATH="$PKG_DIR/$GETTEXT_PACKAGE"

NINJA_VERSION="1.12.1"
NINJA_PACKAGE="ninja-$NINJA_VERSION"
NINJA_PKG_PATH="$PKG_DIR/$NINJA_PACKAGE"

NEOVIM_VERSION="0.11.1"
NEOVIM_PACKAGE="neovim-$NEOVIM_VERSION"
NEOVIM_PKG_PATH="$PKG_DIR/$NEOVIM_PACKAGE"

RIPGREP_VERSION="14.1.1"
RIPGREP_PACKAGE="ripgrep-$RIPGREP_VERSION-x86_64-unknown-linux-musl"
RIPGREP_PKG_PATH="$PKG_DIR/$RIPGREP_PACKAGE"

GO_VERSION="1.24.2"
GO_PACKAGE="go$GO_VERSION.linux-amd64"
GO_PKG_PATH="$PKG_DIR/$GO_PACKAGE"

# Check os and architecture.
if test "$(uname -s)" != "Linux" || test "$(arch)" != "x86_64"; then
  echo "Neovim bootstrapping not supported!"
  exit 1
fi

nodeps=0
for cmd in git tar wget make gcc perl unzip chmod tr awk; do
  if ! command -V $cmd > /dev/null 2>&1; then
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

    tar -xzvf "$STOW_PACKAGE.tar.gz"
    cd "$STOW_PACKAGE" || exit 1
    ./configure && make
  fi
  cat <<EOF > "$BIN_DIR/stow" && chmod +x "$BIN_DIR/stow"
#!/bin/sh
perl -I"$STOW_PKG_PATH/lib" "$STOW_PKG_PATH/bin/stow" "\$@"
EOF
}

install_node() {
  install_stow
  cd "$PKG_DIR" || exit 1
  if ! test -d "$NODE_PKG_PATH"; then
    echo "Package not found, installing NodeJS version $NODE_VERSION..."
    MAJOR_VERSION="$(echo "$NODE_VERSION" | tr '.' ' ' | awk '{print $1}' )"
    ! test -f "$NODE_PACKAGE.tar.gz" &&\
      wget "https://nodejs.org/download/release/latest-v$MAJOR_VERSION.x/$NODE_PACKAGE.tar.gz"
    tar -xzvf "$NODE_PACKAGE.tar.gz"

    export PATH="$NODE_PKG_PATH/bin:$PATH"
    npm install -g tree-sitter-cli
  fi
  stow --target="$BIN_DIR" --stow --dir="$NODE_PACKAGE" bin
}

install_go() {
  install_stow
  cd "$PKG_DIR" || exit 1
  if ! test -d "$GO_PKG_PATH"; then
    echo "Package not found, installing Go version $GO_VERSION..."
      ! test -f $GO_PACKAGE.tar.gz &&\
        wget https://go.dev/dl/$GO_PACKAGE.tar.gz
      tar -xzvf $GO_PACKAGE.tar.gz && mv go $GO_PACKAGE
      mkdir -p "$PKG_DIR/gopath"
  fi

  cat <<EOF > "$BIN_DIR/go" && chmod +x "$BIN_DIR/go"
#!/bin/sh
export GOBIN="$BIN_DIR"
export GOPATH="$PKG_DIR/gopath:\$GOPATH"
"$GO_PKG_PATH/bin/go" "\$@"
EOF

  export GOBIN="$GO_PKG_PATH/bin"
  export GOPATH="$PKG_DIR/gopath"
  "$GO_PKG_PATH/bin/go" install golang.org/x/tools/gopls@latest

  cat <<EOF > "$BIN_DIR/gopls" && chmod +x "$BIN_DIR/gopls"
#!/bin/sh
export GOBIN="$BIN_DIR"
export GOPATH="$PKG_DIR/gopath:\$GOPATH"
"$GO_PKG_PATH/bin/gopls" "\$@"
EOF
}

install_python() {
  # use the python download page.
  # You need to force inclusion of venv for things to work as well.
  install_stow
  cd "$PKG_DIR" || exit 1
  if ! test -d "$PYTHON_PKG_PATH"; then
    echo "Package not found, installing NodeJS version $NODE_VERSION..."
    MAJOR_VERSION="$(echo "$NODE_VERSION" | tr '.' ' ' | awk '{print $1}' )"
    ! test -f "Python-$PYTHON_VERSION.tgz" &&\
      wget "https://www.python.org/ftp/python/$PYTHON_VERSION/$PYTHON_PACKAGE.tgz"
    tar -xzvf "$PYTHON_PACKAGE.tgz"
    cd "$PYTHON_PACKAGE" || exit 1
    mkdir -p python-build
    ./configure\
      --prefix="$(pwd)/python-build"\
      --exec-prefix="$(pwd)/python-build"\
      --disable-test-modules\
      --with-ensurepip=install\
      && make -j4 && make install
  fi
  cd "$PKG_DIR" || exit 1
  stow --target="$BIN_DIR" --stow --dir="$PYTHON_PACKAGE/python-build" bin
}

install_cmake() {
  # https://cmake.org/download/
  # apparently you can do this through pip.
  install_python
  "$BIN_DIR/pip3" install cmake
  stow --target="$BIN_DIR" --stow --dir="$PYTHON_PACKAGE/python-build" bin
}

install_ninja() {
  install_stow
  cd "$PKG_DIR" || exit 1
  if ! test -d "$NINJA_PKG_PATH"; then
    echo "Package not found, installing Ninja version $NINJA_VERSION..."
    ! test -f $NINJA_PACKAGE.zip &&\
      wget "https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip"\
      -O $NINJA_PACKAGE.zip
    mkdir -p "$NINJA_PKG_PATH/bin" && cd "$NINJA_PKG_PATH/bin" || exit 1
    unzip "$PKG_DIR/$NINJA_PACKAGE.zip"
  fi
  cd "$PKG_DIR" || exit 1
  stow --target="$BIN_DIR" --stow --dir="$NINJA_PKG_PATH" bin
}

install_gettext() {
  # this is going to be pain...
  # make sure to ./configure --without-emacs
  install_stow
  cd "$PKG_DIR" || exit 1
  if ! test -d "$GETTEXT_PKG_PATH"; then
    echo "Package not found, installing GetText version $GETTEXT_VERSION..."
    ! test -f $GETTEXT_PACKAGE.tar.gz &&\
      wget "https://ftp.gnu.org/gnu/gettext/$GETTEXT_PACKAGE.tar.gz"
    tar -xzvf $GETTEXT_PACKAGE.tar.gz
    cd $GETTEXT_PACKAGE || exit 1
    mkdir "gettext-build"
    ./configure \
      --disable-java \
      --disable-openmp \
      --disable-libasprintf \
      --disable-curses \
      --disable-threads \
      --disable-rpath \
      --disable-dependency-tracking \
      --without-emacs \
      --without-git \
      --prefix="$(pwd)/gettext-build"\
      --exec-prefix="$(pwd)/gettext-build"\
      && make -j4\
      && make install
    cd "$PKG_DIR" || exit 1
  fi
  stow --target="$BIN_DIR" --stow --dir="$GETTEXT_PACKAGE/gettext-build" bin
}

install_neovim() {
  install_stow
  install_node
  install_python
  install_go
  cd "$PKG_DIR" || exit 1
  if ! test -d "$NEOVIM_PKG_PATH"; then
    echo "Package not found, installing Neovim version $NEOVIM_VERSION..."
    ! test -f "$NEOVIM_PACKAGE.tar.gz"\
      && wget "https://github.com/neovim/neovim/releases/download/v$NEOVIM_VERSION/nvim-linux-x86_64.tar.gz"\
      && mv "nvim-linux-x86_64.tar.gz" "$NEOVIM_PACKAGE.tar.gz"\
      && tar -xzvf "$NEOVIM_PACKAGE.tar.gz"\
      && mv "nvim-linux-x86_64" "$NEOVIM_PACKAGE"

    export PATH="$NEOVIM_PKG_PATH/bin:$PATH"
  fi
  # you need to write a "nvim" script that wraps everything with the correct
  # environment variables.
  mkdir -p "$DIR/build/nvim/config"
  rm -rf "$DIR/build/nvim/config/nvim"
  ln -sf "$DIR" "$DIR/build/nvim/config/nvim"
  cat <<EOF > "$BIN_DIR/nvim" && chmod +x "$BIN_DIR/nvim"
#!/bin/sh
export GOBIN="$BIN_DIR"
export GOPATH="$PKG_DIR/gopath:\$GOPATH"
export PATH="$BIN_DIR:\$PATH"
export XDG_CONFIG_HOME="$DIR/build/nvim/config"
export XDG_DATA_HOME="$DIR/build/nvim/share"
export XDG_STATE_HOME="$DIR/build/nvim/state"
export XDG_CACHE_HOME="$DIR/build/nvim/cache"

"$NEOVIM_PKG_PATH/bin/nvim" "\$@"
EOF
}

install_ripgrep() {
  # see https://github.com/BurntSushi/ripgrep/releases
  install_stow
  cd "$PKG_DIR" || exit 1
  if ! test -d "$RIPGREP_PKG_PATH"; then
    echo "Package not found, installing Ripgrep version $RIPGREP_VERSION..."
    ! test -f $RIPGREP_PACKAGE.tar.gz &&\
      wget "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/$RIPGREP_PACKAGE.tar.gz" &&\
      tar -xzvf "$RIPGREP_PACKAGE.tar.gz"
  fi
  cd "$PKG_DIR" || exit 1
  stow --target="$BIN_DIR" --stow --dir="$PKG_DIR" "$RIPGREP_PACKAGE"
}

install_tmuxs() {
  install_go
  "$BIN_DIR/go" install github.com/junikimm717/tmuxs@latest
  "$BIN_DIR/go" install github.com/junegunn/fzf@latest
}

install_neovim
install_tmuxs
install_ripgrep
