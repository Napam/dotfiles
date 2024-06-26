local cmp = require("cmp")
local lspconfig = require("lspconfig")
local conform = require("conform")
local nvimlint = require("lint")

local border_style = "single"

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = border_style,
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = border_style,
})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP stuff",
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
    vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
    vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
    vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
    vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
    vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)

    -- Some keymaps are in whichkey
  end,
})

vim.diagnostic.config({
  float = {
    source = true,
    focusable = true,
  },
})

local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

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
    function(server)
      lspconfig[server].setup({
        capabilities = lsp_capabilities,
      })
    end,
  },
})

lspconfig.denols.setup({
  root_dir = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc"),
})

lspconfig.tsserver.setup({
  root_dir = require("lspconfig.util").root_pattern("package.json"),
  single_file_support = false,
})

lspconfig.clangd.setup({
  cmd = { "clangd", "--offset-encoding=utf-16" },
})

lspconfig.tailwindcss.setup({
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

lspconfig.sqls.setup({ on_attach = require("sqls").on_attach })

conform.setup({
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
})

conform.formatters.sqlfluff = {
  args = {
    "format",
    "--dialect=postgres",
    "-",
  },
}

-- JS stuff is done using eslint-lsp
-- Python stuff is done using ruff-lsp
nvimlint.linters_by_ft = {
  sql = { "sqlfluff" },
}

nvimlint.linters.sqlfluff.args = {
  "lint",
  "--format=json",
  "--dialect=postgres",
}

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  callback = function()
    nvimlint.try_lint()
  end,
})

require("luasnip.loaders.from_vscode").load()

cmp.setup({
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
})

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
