vim.keymap.set("n", "<leader>o", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)

return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    opts = {},
  },

  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- Autocompletion
  {
    "saghen/blink.cmp",
    -- A release tag makes blink download a prebuilt fuzzy matcher instead of
    -- needing a nightly Rust toolchain to build one.
    version = "1.*",
    event = "InsertEnter",
    dependencies = {
      { "L3MON4D3/LuaSnip" },
    },
    opts = {
      keymap = {
        preset = "none",
        ["<C-l>"] = { "snippet_forward", "fallback" },
        ["<C-h>"] = { "snippet_backward", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "cancel", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-y>"] = { "select_and_accept", "fallback" },
        ["<C-e>"] = { "cancel", "fallback" },
      },
      completion = {
        -- Same as completeopt=menu,menuone,noinsert: the first item is
        -- highlighted but nothing is typed until it is accepted.
        list = { selection = { preselect = true, auto_insert = false } },
        documentation = { auto_show = true },
        ghost_text = { enabled = true },
      },
      snippets = { preset = "luasnip" },
      sources = {
        -- buffer is not listed: blink's lsp source already falls back to it
        -- when the servers return nothing.
        default = { "lazydev", "lsp", "snippets", "path" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- show lazydev's results above LuaLS's, as group_index = 0 did
            score_offset = 100,
          },
        },
      },
      cmdline = { enabled = false },
    },
  },

  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")
      local prettier = { "prettierd", "prettier", stop_after_first = true }
      local prettier_eslint = { "eslint_d", "prettierd", "rustywind" }
      conform.setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "isort", "black" },
          go = { "gofmt" },
          javascript = prettier_eslint,
          typescript = prettier_eslint,
          javascriptreact = prettier_eslint,
          typescriptreact = prettier_eslint,
          svelte = prettier_eslint,
          astro = prettier_eslint,
          css = prettier,
          html = prettier,
          json = prettier,
          yaml = prettier,
          markdown = prettier,
          graphql = prettier,
          nix = { "nixfmt" },
          cpp = { "clang-format" },
          c = { "clang-format" },
          mdx = prettier,
          systemverilog = { "verible" },
          verilog = { "verible" },
        },
      })
      vim.keymap.set({ "n", "v" }, "<leader>ft", function()
        conform.format({
          lsp_fallback = true,
          async = true,
        })
      end)
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim" },
    },
    config = function()
      local lint = require("lint")

      local function eval_fn_or_id(x)
        if type(x) == "function" then
          return x()
        else
          return x
        end
      end

      local filter = function(linters)
        local res = {}
        for filetype, pkgs in pairs(linters) do
          local available = {}
          for _, linter in ipairs(pkgs) do
            local binary = eval_fn_or_id(lint.linters[linter].cmd)
            if vim.fn.executable(binary) == 1 then
              table.insert(available, linter)
            end
          end
          res[filetype] = available
        end
        return res
      end

      lint.linters_by_ft = filter({
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte = { "eslint_d" },
        python = { "pylint", "flake8" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        cpp = { "cpplint" },
      })

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })

      vim.keymap.set("n", "<leader>f", function()
        lint.try_lint()
      end, { desc = "Trigger linting for current file" })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspInstall", "LspStart" },
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "saghen/blink.cmp" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "WhoIsSethDaniel/mason-tool-installer.nvim" },
      { "L3MON4D3/LuaSnip" },
      { "nvim-telescope/telescope.nvim" },
    },
    init = function()
      -- Reserve a space in the gutter
      -- This will avoid an annoying layout shift in the screen
      vim.opt.signcolumn = "yes"
    end,
    config = function()
      local builtin = require("telescope.builtin")

      local caps = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", {
        capabilities = caps,
        cmd_env = { NODE_OPTIONS = "--max-old-space-size=4096" },
      })

      -- svlangserver indexes the filesystem, not git, so gitignoring a build
      -- directory does not keep it out of the index. cocotb writes a generated
      -- .v into sim_build on every run and Vivado fills obj/ with netlists;
      -- indexed, they turn up as extra definitions of modules you are editing.
      vim.lsp.config("svlangserver", {
        settings = {
          systemverilog = {
            excludeIndexing = { "**/sim_build/**", "**/obj/**", "**/.venv/**", "**/venv/**" },
          },
        },

        -- Per-project settings. svlangserver reads no config file of its own --
        -- settings only ever arrive over LSP -- and the .nvim/lspconfig.json in
        -- its README is coc.nvim's mechanism, not native vim.lsp's. So read a
        -- file from the root marker directory and hand it over ourselves.
        --
        -- It lives next to the marker because the marker is already the thing
        -- that defines a project here. Note svlangserver writes its own index to
        -- .nvim (it picks the directory from the client name), so .svlangserver
        -- is ours to use and nothing collides.
        before_init = function(params, config)
          local root = config.root_dir
            or (params.rootUri and vim.uri_to_fname(params.rootUri))
          if not root then
            return
          end

          local path = root .. "/.svlangserver/settings.json"
          local fd = io.open(path, "r")
          if not fd then
            return
          end
          local raw = fd:read("*a")
          fd:close()

          local ok, parsed = pcall(vim.json.decode, raw)
          if not ok or type(parsed) ~= "table" then
            -- Silence here would look identical to "no overrides", and the
            -- symptom (lint errors you thought you had configured away) gives
            -- no hint that a typo is the reason.
            vim.notify("svlangserver: ignoring malformed " .. path, vim.log.levels.WARN)
            return
          end

          -- Shallow per-key, not tbl_deep_extend: deep-extending two lists
          -- merges them index by index, so a project list shorter than the
          -- default would inherit the tail of the default instead of replacing
          -- it. Each setting is replaced whole.
          config.settings = config.settings or {}
          config.settings.systemverilog = vim.tbl_extend(
            "force",
            config.settings.systemverilog or {},
            parsed.systemverilog or {}
          )
        end,
      })

      -- LspAttach is where you enable features that only work
      -- if there is a language server active in the file
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP actions",
        callback = function(event)
          local opts = { buffer = event.buf }

          vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
          vim.keymap.set("n", "gd", builtin.lsp_definitions, opts)
          vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
          vim.keymap.set("n", "gi", builtin.lsp_implementations, opts)
          vim.keymap.set("n", "go", builtin.lsp_type_definitions, opts)
          vim.keymap.set("n", "gr", builtin.lsp_references, opts)
          vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
          vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
          vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
        end,
      })

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_installation = false,
        automatic_enable = true,
      })
      local function enable_if(bin, name)
        if vim.fn.executable(bin) == 1 then vim.lsp.enable(name) end
      end
      enable_if("clangd", "clangd")
      --enable_if("sourcekit-lsp", "sourcekit")
      enable_if("pls", "perlpls")
      enable_if("zls", "zls")
      enable_if("gopls", "gopls")

      -- verilog lsp's
      enable_if("verible-verilog-ls", "verible")
      enable_if("svlangserver", "svlangserver")
      enable_if("svls", "svls")
      enable_if("veridian", "veridian")
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.3",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_snipmate").lazy_load({
        paths = { "./lua/junikim/snippets" },
      })
    end,
  },
}
