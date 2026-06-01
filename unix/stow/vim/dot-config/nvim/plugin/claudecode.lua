-- WARN: no essentials gate — whichkey calls require("opencode") from keymap callbacks.
require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/coder/claudecode.nvim" },
  })

  require("claudecode").setup({})
end)
