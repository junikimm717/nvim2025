vim.keymap.set("n", "<leader>o", vim.diagnostic.open_float, { desc = "Line diagnostics" })

local eslint_configs = {
  "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
  "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
  ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml",
}

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
        formatters = {
          eslint_d = {
            -- eslint_d errors out in a project with no ESLint config, so
            -- every format there reported "Formatter failed".
            condition = function(_, ctx)
              return vim.fs.root(ctx.dirname, eslint_configs) ~= nil
            end,
          },
        },
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
          lsp_format = "fallback",
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

      -- Checked on every run rather than once at startup: a linter installed
      -- mid-session gets picked up, and eslint_d's cmd (a function that looks
      -- for a project-local binary) is resolved for the buffer being linted.
      local function installed(names)
        return vim.tbl_filter(function(name)
          local cmd = eval_fn_or_id(eval_fn_or_id(lint.linters[name] or {}).cmd)
          return type(cmd) == "string" and vim.fn.executable(cmd) == 1
        end, names)
      end

      local function try_lint()
        lint.try_lint(installed(lint.linters_by_ft[vim.bo.filetype] or {}))
      end

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte = { "eslint_d" },
        python = { "pylint", "flake8" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        cpp = { "cpplint" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      -- Not BufEnter: that re-ran pylint on every switch back to a buffer.
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = try_lint,
      })

      -- <leader>f on its own made <leader>ff/fg/fa/fh/ft wait for timeoutlen.
      vim.keymap.set("n", "<leader>fl", try_lint, { desc = "Trigger linting for current file" })
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
      -- marksman is a .NET binary, which aborts on startup when libicu is
      -- missing, as it is on minimal servers and in the bootstrap image.
      -- Invariant globalization only affects culture-specific formatting.
      vim.lsp.config("marksman", {
        cmd_env = { DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1" },
      })

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

      require("mason-lspconfig").setup({
        ensure_installed = {},
        -- stylua's --lsp mode only formats, which conform already does.
        automatic_enable = { exclude = { "stylua" } },
      })
      local function enable_if(bin, name)
        if vim.fn.executable(bin) == 1 then vim.lsp.enable(name) end
      end
      enable_if("clangd", "clangd")
      --enable_if("sourcekit-lsp", "sourcekit")
      enable_if("pls", "perlpls")
      enable_if("zls", "zls")
      enable_if("gopls", "gopls")

      -- verilog lsp's: only the first one installed, since each attaches to
      -- the same filetypes and two would duplicate every diagnostic.
      for _, server in ipairs({
        { "verible-verilog-ls", "verible" },
        { "svlangserver", "svlangserver" },
        { "svls", "svls" },
        { "veridian", "veridian" },
      }) do
        if vim.fn.executable(server[1]) == 1 then
          vim.lsp.enable(server[2])
          break
        end
      end
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.*",
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
