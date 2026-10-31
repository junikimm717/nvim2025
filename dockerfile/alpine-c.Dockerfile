# syntax = docker/dockerfile:1.4.0
FROM alpine:latest

RUN apk add ripgrep nodejs gcc make git fzf npm yarn zip unzip curl tar\
            tree-sitter-cli musl-dev neovim ripgrep clang20-extra-tools\
            musl-dev linux-headers man-db man-pages

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
    -- not marksman: Mason only has a glibc build, so on musl every markdown
    -- buffer stopped on a "failed to spawn" error.
    -- linters and formatters
    "prettierd",
    "eslint_d",
    "rustywind",
  },
  lazy = require("themes.kanagawa"),
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
    "c",
    "cpp",
  }
}
EOF
RUN nvim --headless +Lazy! sync +FullSetup +qa
COPY ./container/.profile /root/.profile

# ash reads .profile only as a login shell; an interactive shell reads $ENV.
ENV ENV=/root/.profile
CMD ["/bin/ash"]
