---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gosum", "gotmpl", "gohtml" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
        ST1000 = false, -- Incorrect or missing package comment
        ST1001 = false, -- Should not use dot imports
        ST1003 = false, -- Naming conventions stuff, e.g. should not use underscores in go names
        ST1020 = false, -- Exported function doc should start with function name
        ST1021 = false, -- Exported type doc should start with type name
      },
      hints = {
        parameterNames = true,
        assignVariableTypes = true,
        constantValues = true,
        compositeLiteralTypes = true,
        compositeLiteralFields = true,
        functionTypeParameters = true,
        rangeVariableTypes = true,
      },
      directoryFilters = { "-**/node_modules", "-**/.git" },
      gofumpt = false, -- handled by conform
      semanticTokens = false, -- treesitter handles highlighting
      staticcheck = true,
      templateExtensions = {"gotmpl", "gohtml", "tmpl" },
      vulncheck = "imports",
      -- "all" (vs default "workspace") so go-impl picker can match stdlib/deps
      -- (e.g. typing "reader" surfaces io.Reader).
      symbolScope = "all",
      -- Fuzzy (vs prefix-only) for better matching in the go-impl picker.
      symbolMatcher = "FastFuzzy",
    },
  },
}
