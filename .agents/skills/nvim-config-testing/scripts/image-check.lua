-- Runs inside a container (mounted at /out by images.sh). Opens one sample per
-- filetype in a real Neovim and reports, per file: filetype, treesitter
-- highlighting, attached language servers (and whether they died). Then:
-- blink's fuzzy implementation, installed parser count, :messages, v:errmsg.
-- Writes /out/$IMG.txt and appends progress to /out/$IMG.progress.
local IMG = os.getenv("IMG")
local out = {}
local function say(s) out[#out + 1] = s end
local function progress(s)
  local f = io.open("/out/" .. IMG .. ".progress", "a")
  if f then f:write(s .. "\n"); f:close() end
end

local samples = {
  ["a.lua"] = "local x = 1", ["a.py"] = "import os", ["a.ts"] = "const x: number = 1",
  ["a.json"] = '{"a":1}', ["a.md"] = "# hi", ["a.mdx"] = "# hi", ["a.c"] = "int main(void){}", ["a.sh"] = "echo hi",
  ["a.html"] = "<div></div>", ["a.tex"] = "\\documentclass{article}", ["a.go"] = "package main",
  ["a.jl"] = "x = 1",
}
vim.fn.mkdir("/tmp/ck", "p")
vim.fn.system({ "git", "init", "-q", "/tmp/ck" })
local names = vim.tbl_keys(samples)
table.sort(names)
for _, n in ipairs(names) do vim.fn.writefile({ samples[n] }, "/tmp/ck/" .. n) end

local i = 0
local function nxt()
  i = i + 1
  if i > #names then
    say("blink fuzzy: " .. tostring(require("blink.cmp.fuzzy").implementation_type))
    say("parsers: " .. #vim.api.nvim_get_runtime_file("parser/*.so", true))
    local m = vim.trim(vim.fn.execute("messages"))
    say("messages: " .. (m == "" and "-" or m:gsub("\n", " | ")))
    say("errmsg: " .. (vim.v.errmsg == "" and "-" or vim.v.errmsg))
    vim.fn.writefile(out, "/out/" .. IMG .. ".txt")
    vim.cmd("qa!")
    return
  end
  progress("opening " .. names[i])
  vim.cmd("edit /tmp/ck/" .. names[i])
  vim.defer_fn(function()
    local cl = {}
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      cl[#cl + 1] = c.name .. (c.initialized and "" or "(not-initialized)") .. (c:is_stopped() and "(STOPPED)" or "")
    end
    say(("%-7s ft=%-10s ts=%-5s lsp=%s"):format(names[i], vim.bo.filetype,
      tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil), table.concat(cl, ",")))
    nxt()
  end, 6000)
end
require("lazy").load({ plugins = { "blink.cmp" } })
vim.defer_fn(nxt, 3000)
