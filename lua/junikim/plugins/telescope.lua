return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local builtin = require("telescope.builtin")
    require("telescope").setup({
      pickers = {
        buffers = { theme = "dropdown" },
        find_files = { theme = "dropdown" },
        git_files = { theme = "dropdown" },
        lsp_references = { theme = "dropdown" },
        lsp_definitions = { theme = "dropdown" },
        lsp_implementations = { theme = "dropdown" },
        lsp_type_definitions = { theme = "dropdown" },
      },
      defaults = {
        -- These are Lua patterns matched anywhere in the path, so a bare
        -- ".git" also hid legit.txt. %f[%w_.] anchors each to the start of
        -- a path component, and the trailing / to a directory.
        file_ignore_patterns = {
          "%f[%w_.]node_modules/",
          "%f[%w_.]%.git/",
          "%f[%w_.]venv/",
          "%f[%w_.]__pycache__/",
          "%f[%w_.]%.pio/",
          "%f[%w_.]%.vscode/",
          "%f[%w_.]%.idea/",
          "%f[%w_.]vendor/",
        },
      },
      extensions = {
        fzf = {},
      },
    })
    require("telescope").load_extension("fzf")

    vim.keymap.set("n", "<C-P>", function()
      -- $PWD is where nvim started; getcwd() follows :cd
      if vim.fs.root(vim.fn.getcwd(), ".git") then
        builtin.git_files()
      else
        builtin.find_files()
      end
    end, {})
    vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
    vim.keymap.set("n", "<leader>fa", builtin.buffers, {})
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
  end,
}
