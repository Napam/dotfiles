if Config.only_essential_plugins() then return end

-- Publish blink integration at sourcing time so blink.lua picks it up
-- regardless of source order.
Config.blink = Config.blink or {}
Config.blink.extra_providers = Config.blink.extra_providers or {}
Config.blink.extra_default_sources = Config.blink.extra_default_sources or {}

Config.blink.extra_providers.lazydev = {
  name = "LazyDev",
  module = "lazydev.integrations.blink",
  score_offset = 100,
}
table.insert(Config.blink.extra_default_sources, "lazydev")

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim" },
  })

  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      -- Load snacks.nvim's type defs when `Snacks` is seen (it sets the global
      -- at runtime, so lua_ls can't infer it statically otherwise).
      { path = "snacks.nvim", words = { "Snacks" } },
    },
  })
end)
