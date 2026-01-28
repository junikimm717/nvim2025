return {
  { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    branch = "master",
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = require("junikim.config").treesitter,
      -- Autoinstall languages that are not installed
      auto_install = true,
      sync_install = false,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        disable = { "perl", "htmldjango", "dockerfile" },
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true, disable = { "ruby", "markdown", "mdx" } },
    },
    config = function(_, opts)
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

      parser_config.mdx = {
        install_info = {
          url = "https://github.com/srazzak/tree-sitter-mdx",
          files = { "src/parser.c", "src/scanner.c" }, -- or just parser.c
          branch = "main",
        },
        filetype = "mdx",
      }
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  { "lervag/vimtex" },
}
