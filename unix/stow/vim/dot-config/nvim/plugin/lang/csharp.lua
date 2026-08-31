if Config.only_essential_plugins() then
  return
end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/seblyng/roslyn.nvim" },
  })

  -- HACK note: roslyn-language-server dies on duplicate didOpen (an nvim client bug,
  -- see plugin/lsp.lua); nothing roslyn-specific to configure here.
  require("roslyn").setup({
    broad_search = true,
  })
end)
