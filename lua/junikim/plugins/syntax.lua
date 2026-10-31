-- tex: VimTeX's own syntax powers its motions, text objects and concealing,
-- and it warns ("Syntax highlighting is controlled by Treesitter!") when
-- treesitter highlighting replaces it.
local ignore_filetypes = { "perl", "htmldjango", "dockerfile", "tex" }
local ignored = {}
for _, ftype in pairs(ignore_filetypes) do
  ignored[ftype] = true
end

vim.api.nvim_create_autocmd("FileType", {
  --pattern = require("junikim.config").treesitter,
  pattern = "*",
  callback = function()
    if ignored[vim.bo.filetype] then
      return
    end

    if not pcall(vim.treesitter.start) then
      return
    end

    -- Indenting needs an indents.scm, which is a separate thing from the
    -- parser: systemverilog, make, gitcommit and gitignore all ship a parser
    -- with no indents query.
    local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
    local has_indents = false
    if lang then
      local ok, query = pcall(vim.treesitter.query.get, lang, "indents")
      has_indents = ok and query ~= nil
    end
    if has_indents then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo[0][0].foldmethod = "expr"
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
  {
    "lervag/vimtex",
    -- Follow releases: master moves its minimum Neovim ahead of releases
    -- (it required 0.12.4 on 2026-10-30, breaking .tex in every image on an
    -- older Neovim) while v2.18 still supports 0.10.
    version = "v2.*",
    init = function()
      -- Without latexmk VimTeX warns on every .tex buffer, e.g. in all the
      -- container images; editing works the same without its compiler.
      vim.g.vimtex_compiler_enabled = vim.fn.executable("latexmk")
    end,
  },
}
