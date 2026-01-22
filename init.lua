require("junikim")
local config = require("junikim.config")

require("lazy").setup({
  { import = "junikim.plugins" },
  config.lazy,
})
