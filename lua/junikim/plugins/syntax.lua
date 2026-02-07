vim.api.nvim_create_autocmd("FileType", {
  pattern = require("junikim.config").treesitter,
  callback = function()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo[0][0].foldmethod = "expr"
    vim.treesitter.start()
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").mdx = {
      install_info = {
        url = "https://github.com/srazzak/tree-sitter-mdx",
        revision = "3aa29e8de1bf0213948a04fe953039b6ab73777b",
      },
    }
  end,
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    branch = "main",
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    config = function(_, opts)
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })
      -- install specified treesitter parsers
      require("nvim-treesitter").install(require("junikim.config").treesitter)
    end,
  },
  { "lervag/vimtex" },
}
