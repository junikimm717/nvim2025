FROM debian:bookworm AS builder

WORKDIR /workspace
RUN apt-get update
RUN apt-get install -y ninja-build gettext cmake unzip curl build-essential file\
    liblapack-dev libblas-dev
RUN curl -LJ https://github.com/neovim/neovim/archive/refs/tags/nightly.tar.gz\
  -o neovim.tar.gz\
  && tar -xzvf neovim.tar.gz\
  && mv neovim-nightly neovim

WORKDIR /workspace/neovim
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo
RUN cd build && cpack -G DEB && mv *.deb neovim.deb

FROM julia:bookworm

RUN julia -e 'using Pkg; Pkg.add(["Preferences", "Finch", "HDF5", "TensorMarket"]);'
RUN julia -e 'using Finch; using HDF5; using TensorMarket;'

COPY --from=builder /workspace/neovim/build/neovim.deb /root/packages/neovim.deb
RUN apt-get update
RUN apt-get install -y ripgrep nodejs gcc make golang git fzf npm zip unzip\
  curl wget tar python3-venv cmake hdf5-tools libhdf5-dev\
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
    "eslint_d",
    "rustywind",
    "julia-lsp",
    "pyright",
    "clangd",
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
