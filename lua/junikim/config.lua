---@class Config
---@field lazy table|nil
---@field mason table|nil
---@field treesitter table|nil
local config = {
  mason = {
    -- language servers
    "tailwindcss-language-server",
    "typescript-language-server",
    "json-lsp",
    "texlab",
    "pyright",
    "lua-language-server",
    "marksman",
    -- linters and formatters
    "prettierd",
    "black",
    "isort",
    "pylint",
    "flake8",
    "cpplint",
    "verible",
    "nixfmt",
    "eslint_d",
    "stylua",
    "shellcheck",
    "rustywind",
  },
  lazy = require("themes.gruvbox"),
  treesitter = {
    "c",
    "cpp",
    "rust",
    "javascript",
    "typescript",
    "tsx",
    "json",
    "html",
    "latex",
    "bash",
    "python",
    "go",
    "css",
    "bibtex",
    "make",
    "vim",
    "lua",
    "markdown",
    "gitignore",
    "toml",
    "yaml",
    "nix",
  },
}

local newconfig = nil
local success, theme = pcall(require, "configs")
if not success then
  local filepath = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "configs", "init.lua"))
  -- vim.fn returns 0/1, and 0 is truthy in Lua. filewritable() is also 0 for
  -- a file that doesn't exist yet, so ask about the directory (2) instead.
  -- The filereadable check keeps a configs/init.lua with an error in it from
  -- being overwritten.
  if vim.fn.filewritable(vim.fs.dirname(filepath)) == 2 and vim.fn.filereadable(filepath) == 0 then
    vim.fn.writefile({ [[return require("configs.catppuccin")]] }, filepath)
    newconfig = require("configs")
  else
    newconfig = require("configs.catppuccin")
  end
else
  newconfig = theme
end

for key, value in pairs(newconfig) do
  config[key] = value
end

return config
