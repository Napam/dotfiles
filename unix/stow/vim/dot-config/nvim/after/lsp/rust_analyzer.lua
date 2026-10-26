---@type vim.lsp.Config
return {
  settings = {
    ["rust-analyzer"] = {
      -- Server-side off; plugin/lsp.lua enables the client capability globally.
      lens = { enable = false },
    },
  },
}
