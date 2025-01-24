return {
  {
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
        vim.keymap.set("n", "<leader>" .. tab, selector(tab))
        tab = tab + 1
      end
      vim.keymap.set("n", "<leader>j", selector(1))
      vim.keymap.set("n", "<leader>k", selector(2))
      vim.keymap.set("n", "<leader>l", selector(3))
      vim.keymap.set("n", "<leader>;", selector(4))

      vim.keymap.set("n", "<leader>p", function()
        local name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
        -- we need to make sure we don't submit empty buffers or terminal bullshit to harpoon
        if #name ~= 0 and string.match(name, "://") == nil then
          harpoon:list():add()
        end
      end)
      vim.keymap.set("n", "<leader>c", function()
        if vim.bo.modified then
          local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
          if choice == 1 then
            vim.cmd.write()
            vim.cmd("bd")
          elseif choice == 2 then
            vim.cmd("bd!")
          end
        else
          vim.cmd("bd")
        end
      end)
      vim.keymap.set("n", "<leader>q", function()
        vim.cmd("bd!")
      end)
      vim.keymap.set("n", "ZB", function()
        vim.cmd("bd!")
      end)
      vim.keymap.set("n", "<leader>h", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)
    end,
  },
  {
    "romgrk/barbar.nvim",
    dependencies = {
      "ThePrimeagen/harpoon",
      "lewis6991/gitsigns.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local barbar = require("barbar")
      local state = require("barbar.state")
      local render = require("barbar.ui.render")
      local harpoon = require("harpoon")

      barbar.setup({
        hide = {
          inactive = true,
        },
        icons = {
          pinned = { filename = true, buffer_index = true },
          diagnostics = { { enabled = true } },
        },
      })

      local function unpin_all()
        for _, buf in ipairs(state.buffers) do
          local data = state.get_buffer_data(buf)
          data.pinned = false
        end
      end

      local function get_buffer_by_mark(mark)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local buffer_path = vim.api.nvim_buf_get_name(buf)

          if buffer_path == "" or mark.value == "" then
            goto continue
          end

          local mark_pattern = mark.value:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
          if string.match(buffer_path, mark_pattern) then
            return buf
          end

          local buffer_path_pattern = buffer_path:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
          if string.match(mark.value, buffer_path_pattern) then
            return buf
          end

          ::continue::
        end
      end

      local function refresh_all_harpoon_tabs()
        local list = harpoon:list()
        unpin_all()
        for _, mark in ipairs(list.items) do
          local buf = get_buffer_by_mark(mark)
          if buf == nil then
            vim.cmd("badd " .. mark.value)
            buf = get_buffer_by_mark(mark)
          end
          if buf ~= nil then
            state.toggle_pin(buf)
          end
        end
        render.update()
      end

      vim.api.nvim_create_autocmd({ "BufEnter", "BufAdd", "BufLeave", "User" }, {
        callback = refresh_all_harpoon_tabs,
      })
    end,
  },
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup()
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
}
