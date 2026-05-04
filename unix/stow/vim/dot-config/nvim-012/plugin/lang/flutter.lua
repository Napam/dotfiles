if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-flutter/flutter-tools.nvim" },
  })

  require("flutter-tools").setup({
    debugger = { enabled = true },
  })
end)
