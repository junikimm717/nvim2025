return {
  {
    "catppuccin/nvim",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        styles = {
          strings = { "italic" },
          comments = { "italic" },
          operators = { "italic" },
          conditionals = { "italic" },
          loops = { "italic" },
          types = { "bold" },
          functions = {},
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
      vim.opt.laststatus = 3
    end,
    opts = {
      options = {
        icons_enabled = true,
        theme = "auto",
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { require("junikim.utils").getWords },
      },
    },
  },
}
