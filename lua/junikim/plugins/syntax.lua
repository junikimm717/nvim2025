return {
  { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs", -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = {
        "c",
        "cpp",
        "rust",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "html",
        "latex",
        "bash",
        "python",
        "go",
        "css",
        "bibtex",
        "make",
        "vim",
        "lua",
        "markdown",
        "gitignore",
        "toml",
        "yaml",
        "nix",
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      sync_install = false,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        disable = { "latex", "perl", "htmldjango" },
      },
      indent = { enable = true, disable = { "ruby" } },
    },
  },
  {
    "davidmh/mdx.nvim",
    config = true,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  { "lervag/vimtex" },
}
