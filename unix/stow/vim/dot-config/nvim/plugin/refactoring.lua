if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  if not Config.use_treesitter_parser then return end

  vim.pack.add({
    { src = "https://github.com/lewis6991/async.nvim" },
    { src = "https://github.com/ThePrimeagen/refactoring.nvim" },
  })

  require("refactoring").setup({})
end)
