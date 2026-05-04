require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/akinsho/bufferline.nvim" },
  })

  require("bufferline").setup({})
end)
