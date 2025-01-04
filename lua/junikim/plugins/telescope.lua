return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
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
        lsp_references = { theme = "ivy" },
        lsp_definitions = { theme = "ivy" },
        lsp_implementations = { theme = "ivy" },
        lsp_type_definitions = { theme = "ivy" },
      },
      extensions = {
        fzf = {},
      },
    })
    require("telescope").load_extension("fzf")

    vim.keymap.set("n", "<C-P>", function()
      if vim.fs.root(0, ".git") then
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
