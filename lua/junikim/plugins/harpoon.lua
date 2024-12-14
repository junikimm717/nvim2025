return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  init = function()
    local harpoon = require("harpoon")

    local function selector(idx)
      local function func()
        return harpoon:list():select(idx)
      end
      return func
    end

    local tab = 1
    while tab <= 9 do
      vim.keymap.set('n', '<leader>' .. tab, selector(tab))
      tab = tab + 1
    end
    vim.keymap.set('n', 'ha', selector(1))
    vim.keymap.set('n', 'hs', selector(2))
    vim.keymap.set('n', 'hd', selector(3))
    vim.keymap.set('n', 'hf', selector(4))

    vim.keymap.set("n", "<leader>p", function() harpoon:list():add() end)
    vim.keymap.set("n", "<leader>c", function()
      if vim.bo.modified then
        local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
        if choice == 1 then
          vim.cmd.write()
          vim.cmd('bd')
        elseif choice == 2 then
          vim.cmd('bd!')
        end
      else
        vim.cmd('bd')
      end
    end)
    vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
  end
}
