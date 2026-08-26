if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/seblyng/roslyn.nvim" },
  })

  require("roslyn").setup({
    broad_search = true,
  })
end)
