return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon.setup({
      settings = {
        save_on_toggle = true,
        tabline = true,
      }
    })

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

    vim.keymap.set("n", "<leader>p", function() harpoon:list():add() end)
    vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
  end
}
