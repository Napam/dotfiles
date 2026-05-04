require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/kylechui/nvim-surround" },
  })

  require("nvim-surround").setup({})
end)
