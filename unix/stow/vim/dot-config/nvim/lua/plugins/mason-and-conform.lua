return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
        "bashls",
        "denols",
        "eslint",
        "goimports",
        "gopls",
        "graphql",
        "html",
        "jsonls",
        "lua_ls",
        "ruff",
        "rust_analyzer",
        "rustywind",
        "svelte",
        "tailwindcss",
        "templ",
        "ts_ls",
        "yamlls",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      local conform = require("conform")
      conform.setup({
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
      })
    end,
  },
}
