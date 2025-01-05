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
}
