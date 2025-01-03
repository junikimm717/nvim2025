vim.g.mapleader = " "
require("junikim")

local themepkgs = nil
local success, theme = pcall(require, "configs")
if not success then
  local filepath = vim.fs.joinpath (vim.fn.stdpath('config'), 'lua', 'configs', 'init.lua')
  local file = io.open(filepath, 'w')
  if file ~= nil then
    file:write('return require("configs.catppuccin")')
    file:close()
    themepkgs = require("configs")
  else
    themepkgs = require("configs.catppuccin")
  end
else
  themepkgs = theme
end


require("lazy").setup({
  { import = 'junikim.plugins' },
  themepkgs
})
