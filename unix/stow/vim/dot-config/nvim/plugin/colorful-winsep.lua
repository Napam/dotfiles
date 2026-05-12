require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/nvim-zh/colorful-winsep.nvim" },
  })

  require("colorful-winsep").setup({})
end)
