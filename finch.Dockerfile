FROM julia:alpine

RUN julia -e 'using Pkg; Pkg.add("Finch")'

RUN apk add ripgrep nodejs gcc make git fzf npm zip unzip curl tar\
            tree-sitter-cli musl-dev neovim clang19-extra-tools python3 hdf5\
            cmake musl-utils

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
    "clang-format",
  },
  lazy = require("themes.kanagawa"),
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

COPY ./container/.profile /root/.profile

CMD ["/bin/ash"]
