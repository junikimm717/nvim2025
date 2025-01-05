---@class Config
---@field lazy table
---@field mason table
local config = {
  mason = {
    -- language servers
    "tailwindcss-language-server",
    "typescript-language-server",
    "json-lsp",
    "texlab",
    "pyright",
    "ltex-ls",
    "lua-language-server",
    "marksman",
    -- linters and formatters
    "prettierd",
    "black",
    "pylint",
    "eslint_d",
    "stylua",
    "shellcheck",
    "rustywind",
  },
  lazy = require("themes.gruvbox"),
}

local newconfig = nil
local success, theme = pcall(require, "configs")
if not success then
  local filepath = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "configs", "init.lua"))
  if vim.fn.filewritable(filepath) then
    vim.fn.writefile({[[return require("configs.catppuccin")]]}, filepath)
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
