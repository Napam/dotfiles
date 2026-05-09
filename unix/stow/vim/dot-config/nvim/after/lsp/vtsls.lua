-- WARN: vtsls (modern ts_ls successor). Inlay hints schema differs from ts_ls.
---@type vim.lsp.Config
return {
  settings = {
    typescript = {
      inlayHints = {
        enumMemberValues = { enabled = true },
        parameterNames = { enabled = "all" },
      },
    },
    javascript = {
      inlayHints = {
        enumMemberValues = { enabled = true },
        parameterNames = { enabled = "all" },
      },
    },
  },
}
