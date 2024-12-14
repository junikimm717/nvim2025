return {
  "L3MON4D3/LuaSnip",
  -- follow latest release.
  version = "v2.*",
  build = "make install_jsregexp",
  config = function()
    require("luasnip.loaders.from_snipmate").lazy_load({
      paths = "./lua/junikim/snippets"
    })
  end
}
