# syntax = docker/dockerfile:1.4.0
FROM alpine:latest

RUN apk add ripgrep nodejs gcc make git fzf npm yarn zip unzip curl tar\
            tree-sitter-cli musl-dev neovim

COPY . /root/.config/nvim

WORKDIR /workspace
RUN <<EOF cat > /root/.config/nvim/lua/configs/init.lua
---@type Config
return {
  mason = {
    -- language servers
    "tailwindcss-language-server",
    "typescript-language-server",
    "json-lsp",
    "marksman",
    -- linters and formatters
    "prettierd",
    "eslint_d",
    "rustywind",
  },
  lazy = require("themes.tokyonight"),
  treesitter = {
    "javascript",
    "typescript",
    "tsx",
    "json",
    "html",
    "css",
    "bibtex",
    "markdown",
    "gitignore",
    "toml",
    "yaml",
  }
}
EOF
RUN nvim --headless +Lazy! sync +FullSetup +qa

CMD ["/bin/ash"]
