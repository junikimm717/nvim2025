return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      local harpoon = require("harpoon")
      -- Without setup, harpoon never saves a mark's cursor position on
      -- BufLeave or syncs the list on exit.
      harpoon:setup()

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
        -- Every animation runs its own frame-rate timer that re-renders the
        -- whole tabline. Wiping or re-adding many buffers at once (as the
        -- harpoon refresh below does) starts one per buffer, and the timers
        -- outran the event loop: Neovim sat at 100% CPU and stopped
        -- responding.
        animation = false,
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

      -- Compare whole paths: matching one as a substring of the other pins
      -- data.lua for a mark on a.lua.
      local function get_buffer_by_mark(mark)
        if mark.value == "" then
          return nil
        end
        local mark_path = vim.fs.normalize(vim.fn.fnamemodify(mark.value, ":p"))
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local buffer_path = vim.api.nvim_buf_get_name(buf)
          if buffer_path ~= "" and vim.fs.normalize(buffer_path) == mark_path then
            return buf
          end
        end
      end

      local function refresh_all_harpoon_tabs()
        local list = harpoon:list()
        unpin_all()

        for _, mark in ipairs(list.items) do
          local buf = get_buffer_by_mark(mark)
          if buf == nil then
            vim.cmd("badd " .. vim.fn.fnameescape(mark.value))
            buf = get_buffer_by_mark(mark)
          end

          if buf ~= nil then
            state.toggle_pin(buf)
          end
        end
        render.update()
      end
      -- Treesitter, indent and folds are set up by the FileType autocmd in
      -- syntax.lua; redoing it here put treesitter's indentexpr on buffers
      -- whose language has no indents query.
      vim.api.nvim_create_autocmd({ "BufEnter", "BufAdd", "BufLeave" }, {
        callback = refresh_all_harpoon_tabs,
      })
      harpoon:extend({
        ADD = refresh_all_harpoon_tabs,
        REMOVE = refresh_all_harpoon_tabs,
        REORDER = refresh_all_harpoon_tabs,
        LIST_CHANGE = refresh_all_harpoon_tabs,
      })
    end,
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        watch_for_changes = true,
        view_options = {
          show_hidden = true,
        },
      })
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
}
