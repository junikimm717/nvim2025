require("junikim")
local config = require("junikim.config")
vim.g["fcitx5_remote"] = 1

require("lazy").setup({
  { import = "junikim.plugins" },
  config.lazy,
})
