require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/A7Lavinraj/fyler.nvim" },
  })

  require("fyler").setup({})
end)
