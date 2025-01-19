return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "RRethy/base16-nvim" },
    init = function()
      vim.opt.laststatus = 3
    end,
    opts = {
      options = {
        icons_enabled = true,
        theme = "base16",
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
