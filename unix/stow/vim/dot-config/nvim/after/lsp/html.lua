---@brief
---
--- https://github.com/hrsh7th/vscode-langservers-extracted
---
--- Tag and attribute completion/hover for HTML. Jinja delimiters are plain text
--- to the server, so it only supplies the surrounding markup.
---@type vim.lsp.Config
return {
  filetypes = { "html", "htmldjango", "jinja" },
}
