---@type vim.lsp.Config
return {
  -- WARN: conform.nvim handles JS/TS formatting via prettier/eslint_d.
  -- Disabling here prevents eslint-lsp from advertising formatting capability.
  settings = { format = false },
}
