if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/AbaoFromCUG/websocket.nvim" },
    { src = "https://github.com/SUSTech-data/neopyter" },
  })

  require("neopyter").setup({
    mode = "direct",
    remote_address = "127.0.0.1:9001",
    file_pattern = { "*.ju.*" },
    on_attach = function(_bufnr) end,
  })
end)
