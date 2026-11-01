-- Fold with treesitter where the language has a folds query, and with the
-- language server's folding ranges otherwise: tex is kept off treesitter for
-- VimTeX, and the mdx parser has no folds query (texlab and mdx-analyzer both
-- send folding ranges).
--
-- foldmethod and foldexpr are window options, so they have to be set on every
-- window showing the buffer, including ones it enters later. Setting them only
-- in FileType misses buffers loaded in the background (harpoon's select calls
-- bufload first): their FileType runs in a hidden autocmd window, and the
-- window they are then shown in keeps foldmethod=manual.
local function set_folds(buf, win)
  local foldexpr
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local ok, query = pcall(vim.treesitter.query.get, lang or "", "folds")
  if vim.treesitter.highlighter.active[buf] and ok and query then
    foldexpr = "v:lua.vim.treesitter.foldexpr()"
  elseif #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/foldingRange" }) > 0 then
    foldexpr = "v:lua.vim.lsp.foldexpr()"
  else
    return
  end
  vim.wo[win][0].foldmethod = "expr"
  vim.wo[win][0].foldexpr = foldexpr
end

local function set_folds_everywhere(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    set_folds(buf, win)
  end
end

local group = vim.api.nvim_create_augroup("junikim_folds", {})

-- syntax.lua requires this after its FileType autocmd, so treesitter has
-- started by the time this one runs.
vim.api.nvim_create_autocmd({ "FileType", "LspAttach" }, {
  group = group,
  callback = function(event)
    set_folds_everywhere(event.buf)
  end,
})

-- Neovim keeps which folds are closed only in memory, so they are gone after
-- a restart or :bdelete. Save them in a view when a file leaves a window and
-- load it the first time the file is shown again. Only folds and cursor:
-- "options" would also save foldmethod/foldexpr and fight set_folds.
vim.opt.viewoptions = { "folds", "cursor" }

-- Not in the hidden autocmd window bufload uses (harpoon's select), which
-- also gets BufWinEnter: the view would be loaded into it and thrown away.
local function has_view(buf)
  return vim.bo[buf].buftype == ""
    and vim.api.nvim_buf_get_name(buf) ~= ""
    and vim.fn.win_gettype() ~= "autocmd"
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  callback = function(event)
    set_folds(event.buf, vim.api.nvim_get_current_win())
    -- Only once per load: within a session Neovim already remembers folds,
    -- and reloading the view on every entry would move the cursor back.
    if has_view(event.buf) and not vim.b[event.buf].view_loaded then
      vim.b[event.buf].view_loaded = true
      vim.cmd("silent! loadview")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinLeave", {
  group = group,
  callback = function(event)
    -- mkview saves the current window, which may be showing another buffer.
    local current = vim.api.nvim_get_current_buf() == event.buf
    if current and has_view(event.buf) and vim.b[event.buf].view_loaded then
      vim.cmd("silent! mkview")
    end
  end,
})
