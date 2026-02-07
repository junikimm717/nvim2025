if vim.fn.executable("macism") == 1 then
  return {
    "keaising/im-select.nvim",
    config = function()
      require("im_select").setup {
        default_im_select = "com.apple.keylayout.US",
        async_switch_im = true,
        set_previous_events = { "InsertEnter" },
        set_default_events = { "InsertLeave", "CmdlineLeave" }
      }
    end
  }
elseif vim.fn.executable("fcitx5-remote") == 1 then
  vim.g["fcitx5_remote"] = "fcitx5-remote"
  return {
    "lilydjwg/fcitx.vim"
  }
else
  return {}
end
