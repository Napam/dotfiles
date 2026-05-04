---@type vim.lsp.Config
return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "gha", "dependabot", "yaml.docker-compose", "yaml.gitlab" },
  root_markers = { ".git" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = {
        enable = false, -- using b0o/SchemaStore.nvim instead
        url = "", -- WARN: avoid TypeError in yaml-language-server
      },
      schemas = require("schemastore").yaml.schemas(),
      validate = true,
      keyOrdering = false, -- WARN: default true; flags any non-alphabetical map as error
      format = { enable = false }, -- delegate to conform.nvim
    },
  },
}
