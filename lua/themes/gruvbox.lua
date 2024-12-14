return {
  {
    "ellisonleao/gruvbox.nvim",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require('gruvbox').setup {
      }

      local day = 9
      local night = 18
      local hour = os.date("*t").hour

      local themes = { "gruvbox", "gruvbox" }
      local theme = 1

      if day <= hour and hour < night then
        theme = 1
      else
        theme = 2
      end
      vim.cmd.colorscheme(themes[theme])
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

      local function toggletheme()
        if theme == 1 then
          theme = 2
          vim.cmd('set background=dark')
        else
          theme = 1
          vim.cmd('set background=light')
        end
      end

      vim.api.nvim_create_user_command("ToggleTheme", toggletheme, {})
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    init = function()
      vim.opt.laststatus = 3
    end,
    opts = {
      options = {
        icons_enabled = true,
        theme = 'auto',
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { require('themes.utils').getWords },
      },
    }
  },
}
