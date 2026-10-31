FROM debian:bookworm AS builder

# Same version as pkgs/*.sh. The moving nightly tag meant two builds of one
# commit could ship different editors.
ARG NEOVIM_VERSION=0.12.6

WORKDIR /workspace
RUN apt-get update && apt-get install -y ninja-build gettext cmake unzip curl build-essential file
RUN curl -LJ https://github.com/neovim/neovim/archive/refs/tags/v$NEOVIM_VERSION.tar.gz\
  -o neovim.tar.gz \
  && tar -xzvf neovim.tar.gz\
  && mv neovim-$NEOVIM_VERSION neovim

WORKDIR /workspace/neovim
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo
RUN cd build && cpack -G DEB && mv *.deb neovim.deb

FROM julia:bookworm

RUN julia -e 'using Pkg; Pkg.add(["Preferences", "Finch", "HDF5", "TensorMarket", "JSON", "BenchmarkTools"]);'
#RUN julia -e 'using Finch; using HDF5; using TensorMarket; using JSON;'

# Debian's nodejs is 18; typescript-language-server 6 requires Node >= 22.
COPY --from=node:24-bookworm-slim /usr/local /usr/local
COPY --from=builder /workspace/neovim/build/neovim.deb /root/packages/neovim.deb
RUN apt-get update && apt-get install -y ripgrep gcc make golang git fzf zip unzip\
  curl wget tar python3-venv cmake hdf5-tools libhdf5-dev\
  liblapack-dev libopenblas-dev file clangd\
  /root/packages/neovim.deb
RUN npm install -g tree-sitter-cli

COPY . /root/.config/nvim

WORKDIR /workspace
RUN <<EOF cat > /root/.config/nvim/lua/configs/init.lua
---@type Config
return {
  mason = {
    -- language servers
    "json-lsp",
    -- linters and formatters
    "prettierd",
    "julia-lsp",
    "pyright",
    "clang-format",
  },
  lazy = require("themes.tokyonight"),
  treesitter = {
    "json",
    "python",
    "markdown",
    "gitignore",
    "toml",
    "yaml",
    "julia",
    "c",
    "cpp",
    "bash",
    "make",
    "cmake",
  }
}
EOF
RUN nvim --headless +Lazy! sync +FullSetup +qa

COPY ./container/.profile /root/.bashrc

CMD ["/bin/bash"]
