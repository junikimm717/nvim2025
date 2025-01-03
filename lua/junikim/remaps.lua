vim.g.mapleader = " "

vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<C-h>", "<C-w>h")

vim.keymap.set("n", "<F5>", ":w|:!./test.sh<CR>")

-- hacks
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "gq", "gw")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
vim.keymap.set("n", "<leader>X", "<cmd>!chmod -x %<CR>", { silent = true })

-- execute file
vim.keymap.set("n", "<leader>r", "<cmd>so ~/.config/nvim/init.lua<CR>")
vim.keymap.set("n", "<leader>e", "<cmd>!%:p<CR>", { silent = true })

if os.getenv("TMUX") ~= nil then
  vim.keymap.set("n", "<C-f>", [[<cmd>silent !tmux neww tmuxs\; setenv WORKSPACES $WORKSPACES \;<CR>]])
else
  local function unavailable()
    print("Not in a tmux session")
  end
  vim.keymap.set("n", "<C-f>", unavailable)
end
