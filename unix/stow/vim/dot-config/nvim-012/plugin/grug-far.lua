require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/MagicDuck/grug-far.nvim" },
  })

  require("grug-far").setup({})
end)
