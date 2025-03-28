return {
  "stevearc/conform.nvim",
  dependencies = { "williamboman/mason.nvim" },
  opts = {
    formatters_by_ft = {
      sh = { "shfmt" },
      zsh = { "shfmt" },
      lua = { "stylua" },
      sql = { "sql_formatter" },
      bash = { "shfmt" },
      python = { "ruff_format", "ruff_organize_imports" },
      markdown = { "prettierd" },
      javascript = { "prettierd", "rustywind" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      javascriptreact = { "prettierd" },
      graphql = { "prettierd" },
      go = { "goimports", lsp_format = "last" },
      templ = { "templ", "html", "rustywind", "goimports" },
      typst = { "typstyle" },
    },
  },
}
