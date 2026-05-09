---@type vim.lsp.Config
return {
  root_markers = { "typst.toml", ".git" },
  settings = {
    formatterMode = "typstyle",
    formatterProseWrap = true,
    fontPaths = { "fonts" },
  },
}
