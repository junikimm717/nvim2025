vim.opt.mouse:append("a")
vim.opt.guicursor = ""
vim.opt.number = true
vim.opt.linebreak = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftround = true
vim.opt.autoindent = true
vim.opt.textwidth = 80
vim.opt.colorcolumn = "80"
vim.opt.list = true
vim.opt.wrap = false
vim.opt.conceallevel = 1
-- vim.o.sms = true

-- ufo config stuff?
vim.o.foldcolumn = "1" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.opt.splitbelow = false
vim.opt.splitright = false

vim.g.indentLine_fileTypeExclude = { "text", "tex" }

vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.nu = true
vim.opt.rnu = true
vim.opt.termguicolors = true

vim.opt.scrolloff = 7

vim.cmd("filetype plugin indent on")
vim.cmd("filetype on")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function(args)
    vim.bo.textwidth = 0
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.ms", "*.me", "*.mom" },
  callback = function(args)
    vim.bo.filetype = "groff"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "tex", "text" },
  callback = function(args)
    vim.o.smarttab = false
    vim.bo.autoindent = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "slang" },
  callback = function(args)
    vim.bo.cindent = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
    vim.bo.autoindent = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function(args)
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = false
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.preserveindent = true
    vim.bo.copyindent = true
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(args)
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})
