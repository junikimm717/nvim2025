vim.g.mapleader = " "
require("junikim")

local function script_path()
  local str = debug.getinfo(2, 'S').source:sub(2)
  return str:match('(.*' .. '/' .. ')')
end

local themepkgs = nil
local success, theme = pcall(require, "themes")
if not success then
  local file = io.open(script_path() .. './lua/themes/init.lua', 'w')
  if file ~= nil then
    file:write('return require("themes.catppuccin")')
    file:close()
    themepkgs = require("themes")
  else
    themepkgs = require("themes.everforest")
  end
else
  themepkgs = theme
end


require("lazy").setup({
  { import = 'junikim.plugins' },
  themepkgs
})
