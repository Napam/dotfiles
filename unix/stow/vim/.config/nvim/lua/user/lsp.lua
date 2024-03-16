local cmp = require("cmp")
local lsp_zero = require("lsp-zero").preset("recommended")
lsp_zero.on_attach(function(_, bufnr)
  local opts = { buffer = bufnr }
  lsp_zero.default_keymaps(opts)

  vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
  vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
end)

lsp_zero.setup()

vim.diagnostic.config({
  float = {
    source = true,
    border = "single",
    focusable = true,
  },
})

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "bashls",
    "html",
    "jsonls",
    "lua_ls",
    "pyright",
    "rust_analyzer",
    "tsserver",
    "yamlls",
    "denols",
    "graphql",
    "svelte",
    "eslint",
    "tailwindcss",
  },
  handlers = {
    lsp_zero.default_setup,
  },
})

require("lspconfig").denols.setup({
  root_dir = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc"),
})

require("lspconfig").tsserver.setup({
  root_dir = require("lspconfig.util").root_pattern("package.json"),
  single_file_support = false,
})

require("lspconfig").clangd.setup({
  cmd = { "clangd", "--offset-encoding=utf-16" },
})

require("lspconfig").tailwindcss.setup({
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          "\\w+Class=\\{?['\"]([^'\"]*)\\}?",
          { "(?:twMerge|twJoin)\\(([^;]*)[\\);]", "[`'\"`]([^'\"`;]*)[`'\"`]" },
          "(?:\\b(?:const|let|var)\\s+)?[\\w$_]*(?:[Ss]tyles|[Cc]lasses|[Cc]lassnames|[Cc]lass)[\\w\\d]*\\s*(?:=|\\+=)\\s*['\"`]([^'\"`]*)['\"`]",
        },
      },
    },
  },
})

require("conform").setup({
  formatters_by_ft = {
    sh = { "shfmt" },
    zsh = { "shfmt" },
    lua = { "stylua" },
    sql = { "sqlfluff" },
    bash = { "shfmt" },
    python = { "ruff" },
    markdown = { "prettierd" },
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
    javascriptreact = { "prettierd" },
  },

  formatters = {
    sqlfluff = {
      meta = {
        url = "https://github.com/sqlfluff/sqlfluff",
        description = "A modular SQL linter and auto-formatter with support for multiple dialects and templated code.",
      },
      command = "sqlfluff",
      args = { "fix", "--dialect=postgres", "-" },
      stdin = true,
      cwd = require("conform.util").root_file({
        ".sqlfluff",
        "pep8.ini",
        "pyproject.toml",
        "setup.cfg",
        "tox.ini",
      }),
      require_cwd = false,
    },
  },
})

-- Not really using linters explicitly as I'm using LSP
-- require("lint").linters_by_ft = {
--   javascript = { "eslint" },
--   typescript = { "eslint" },
--   typescriptreact = { "eslint" },
--   javascriptreact = { "eslint" },
-- }

require("luasnip.loaders.from_vscode").load()

local cmp_window = require("cmp.config.window")
cmp.setup({
  window = {
    completion = cmp_window.bordered(),
    documentation = cmp_window.bordered(),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "copilot" },
    { name = "luasnip" },
    { name = "treesitter" },
  },
  mapping = {
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    }),
    ["<TAB>"] = cmp.mapping.select_next_item(),
    ["<S-TAB>"] = cmp.mapping.select_prev_item(),
  },
  formatting = lsp_zero.cmp_format(),
})

local lspconfig = require("lspconfig")

lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. "/lua"] = true,
        },
      },
    },
  },
})
