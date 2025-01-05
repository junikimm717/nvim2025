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
