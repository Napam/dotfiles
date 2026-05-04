if Config.only_essential_plugins() then return end

vim.pack.add({
  { src = "https://github.com/j-hui/fidget.nvim" },
})

require("fidget").setup({})
