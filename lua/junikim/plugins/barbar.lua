return {
  'romgrk/barbar.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  init = function()
    vim.g.barbar_auto_setup = false
    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    -- Move to previous/next
    map('n', '<leader>,', '<Cmd>BufferPrevious<CR>', opts)
    map('n', '<leader>.', '<Cmd>BufferNext<CR>', opts)
    -- Re-order to previous/next
    map('n', '<leader><', '<Cmd>BufferMovePrevious<CR>', opts)
    map('n', '<leader>>', '<Cmd>BufferMoveNext<CR>', opts)
    -- Goto buffer in position...
    map('n', '<leader>1', '<Cmd>BufferGoto 1<CR>', opts)
    map('n', '<leader>2', '<Cmd>BufferGoto 2<CR>', opts)
    map('n', '<leader>3', '<Cmd>BufferGoto 3<CR>', opts)
    map('n', '<leader>4', '<Cmd>BufferGoto 4<CR>', opts)
    map('n', '<leader>5', '<Cmd>BufferGoto 5<CR>', opts)
    map('n', '<leader>6', '<Cmd>BufferGoto 6<CR>', opts)
    map('n', '<leader>7', '<Cmd>BufferGoto 7<CR>', opts)
    map('n', '<leader>8', '<Cmd>BufferGoto 8<CR>', opts)
    map('n', '<leader>9', '<Cmd>BufferGoto 9<CR>', opts)
    map('n', '<leader>0', '<Cmd>BufferLast<CR>', opts)
    -- Pin/unpin buffer
    map('n', '<leader>p', '<Cmd>BufferPin<CR>', opts)
    map('n', '<leader>i', '<Cmd>BufferPick<CR>', opts)
    -- Close buffer
    map('n', '<leader>c', '<Cmd>w|BufferClose<CR>', opts)
    map('n', '<leader>q', '<Cmd>BufferClose!<CR>', opts)
  end,
  opts = {
    -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
    -- animation = true,
    -- insert_at_start = true,
    -- …etc.
  },
  version = '^1.9.0', -- optional: only update when a new 1.x version is released
}
