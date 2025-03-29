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
}
