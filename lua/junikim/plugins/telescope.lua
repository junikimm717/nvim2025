return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  config = function()
    local builtin = require("telescope.builtin")
    local path = require("plenary.path")
    require('telescope').setup {
      pickers = {
        find_files = { theme = "ivy" },
        git_files = { theme = "ivy" },
        buffers = { theme = "ivy" },
        help_tags = { theme = "ivy" },
        live_grep = { theme = "ivy" },
      },
      extensions = {
        fzf = {},
      }
    }
    require('telescope').load_extension('fzf')

    local function git_exists()
      local p = "."
      while true do
        local gitpath = p .. "/.git"
        local d = io.open(gitpath)
        if d then
          d:close()
          return true
        else
          p = p .. "/.."
        end
        if path:new(p):absolute() == "/" then
          return false
        end
      end
    end

    vim.keymap.set('n', '<C-P>', function()
      if git_exists() then
        builtin.git_files()
      else
        builtin.find_files()
      end
    end, {})
    vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>fa', builtin.buffers, {})
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
  end
}
