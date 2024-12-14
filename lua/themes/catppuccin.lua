return {
  {
    "catppuccin/nvim",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require('catppuccin').setup {
        transparent_background = true,
      }

      local day = 9
      local night = 18
      local hour = os.date("*t").hour

      local themes = { "catppuccin-macchiato", "catppuccin-mocha" }
      local theme = 1

      if day <= hour and hour < night then
        theme = 1
      else
        theme = 2
      end
      vim.cmd.colorscheme(themes[theme])

      local function toggletheme()
        if theme == 1 then
          theme = 2
        else
          theme = 1
        end
        vim.cmd.colorscheme(themes[theme])
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
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
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
