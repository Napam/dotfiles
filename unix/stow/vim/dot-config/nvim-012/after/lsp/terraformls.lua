---@type vim.lsp.Config
return {
  cmd = { "terraform-ls", "serve" },
  filetypes = { "terraform", "tf", "terraform-vars" },
  root_markers = { ".terraform", "terraform" },
  -- WARN: terraform-ls semantic tokens responses for heredoc blocks with
  -- template interpolation freeze Neovim 0.12. Disable; treesitter handles it.
  capabilities = {
    textDocument = {
      ---@diagnostic disable-next-line: assign-type-mismatch
      semanticTokens = vim.NIL,
    },
  },
}
