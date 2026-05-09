---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local root = config.root_dir or vim.uv.cwd()
    return vim.lsp.rpc.start({ "codebook-lsp", "-r", root, "serve" }, dispatchers)
  end,
  filetypes = {
    "c",
    "css",
    "gitcommit",
    "go",
    "haskell",
    "html",
    "java",
    "javascript",
    "javascriptreact",
    "lua",
    "markdown",
    "php",
    "python",
    "ruby",
    "rust",
    "swift",
    "toml",
    "text",
    "typescript",
    "typescriptreact",
    "typst",
    "zig",
  },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "codebook.toml", ".codebook.toml" })
    if root then
      on_dir(root)
    end
  end,
}
