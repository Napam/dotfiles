require("lazyload").on_vim_enter(function()
  vim.pack.add {
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
  }

  require("gitsigns").setup({})
end)
