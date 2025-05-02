#!/bin/sh

# This is a bootstrapping script meant for setting up dev environments on hpc
# clusters for personal use. As a result, it only supports x86_64 at the moment.

# This script assumes existence of the following tools:
# 1. basic build tools (gcc, etc), not including cmake
# 2. perl

# I will freely assume that this system has basic build tools and perl
# installed. Installing those myself would be a massive pain in the ass anw.

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

GETTEXT_VERSION="0.24"
GETTEXT_PACKAGE="gettext-$GETTEXT_VERSION"
GETTEXT_PKG_PATH="$PKG_DIR/$GETTEXT_PACKAGE"

GO_VERSION="1.24.2"
GO_PACKAGE="go$GO_VERSION.linux-amd64"
GO_PKG_PATH="$PKG_DIR/$GO_PACKAGE"


# Check os and architecture.
if test "$(uname -s)" != "Linux" || test "$(arch)" != "x86_64"; then
  echo "Neovim bootstrapping not supported!"
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
    echo "(?!)bin" >> "$NODE_PKG_PATH/.stow-local-ignore"

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
      mkdir -p gopath
  fi
  cat <<EOF > "$BIN_DIR/go" && chmod +x "$BIN_DIR/go"
#!/bin/sh
export GOBIN="$BIN_DIR"
export GOPATH="$PKG_DIR/gopath"
"$GO_PKG_PATH/bin/go" "\$@"
EOF
}

install_python() {
  # use the python download page.
  # You need to force inclusion of venv for things to work as well.
  exit
}

install_cmake() {
  # https://cmake.org/download/
  # apparently you can do this through pip.
  exit
}

install_ninja() {
  # https://cmake.org/download/
  # apparently you can do this through pip.
  exit
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
  fi
  stow --target="$BIN_DIR" --stow --dir="$GETTEXT_PACKAGE/gettext-build" bin
}

install_clangd() {
  # TODO
  exit
}

install_ripgrep() {
  # see https://github.com/BurntSushi/ripgrep/releases
  exit
}

install_tmuxs() {
  # install ripgrep and tmuxs
  exit
}
