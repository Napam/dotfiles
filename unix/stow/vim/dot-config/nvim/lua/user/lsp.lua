local cmp = require("cmp")
local lspconfig = require("lspconfig")
local conform = require("conform")
local nvimlint = require("lint")
local mason_registry = require("mason-registry")

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
    "basedpyright",
    "ruff",
    "rust_analyzer",
    "ts_ls",
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

lspconfig.basedpyright.setup({
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
      },
    },
  },
})

lspconfig.denols.setup({
  root_dir = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc"),
})

local vue_language_server_path = mason_registry
  .get_package("vue-language-server")
  :get_install_path() .. "/node_modules/@vue/language-server"

lspconfig.ts_ls.setup({
  root_dir = require("lspconfig.util").root_pattern("package.json"),
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = vue_language_server_path,
        languages = { "vue" },
      },
    },
  },
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
  single_file_support = false,
})

lspconfig.volar.setup({})

lspconfig.clangd.setup({
  cmd = { "clangd", "--offset-encoding=utf-16" },
})

lspconfig.tailwindcss.setup({
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          "\\w+Class=\\{?['\"]([^'\"]*)\\}?",
          { "(?:twMerge|twJoin|Merge)\\(([^;]*)[\\);]", "[`'\"`]([^'\"`;]*)[`'\"`]" },
          "(?:\\b(?:const|let|var)\\s+)?[\\w$_]*(?:[Ss]tyles|[Cc]lasses|[Cc]lassnames|[Cc]lass)[\\w\\d]*\\s*(?:=|\\+=)\\s*['\"`]([^'\"`]*)['\"`]",
        },
      },
    },
  },
})

-- lspconfig.sqls.setup({ on_attach = require("sqls").on_attach })

lspconfig.yamlls.setup({
  settings = {
    yaml = {
      schemas = {
        -- ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "/openapi/*",
      },
    },
  },
})

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
  },

  formatters = {
    sql_formatter = function(_)
      return {
        cwd = require("conform.util").root_file({ ".sql-formatter.json" }),
        require_cwd = true,
        -- according to docs it should find .sql-formatter.json itself but doesn't :)
        -- this is kinda suboptimal and weird since the root dir won't necessarily match
        -- with the config file.
        args = vim.fn.empty(vim.fn.glob(".sql-formatter.json")) == 0
            and { "--config", ".sql-formatter.json" }
          or nil,
      }
    end,
  },
})

-- conform.formatters.sleek = {
--   args = {
--     "format",
--     "--dialect=postgres",
--     "-",
--   },
-- }

-- JS stuff is done using eslint-lsp
-- Python stuff is done using ruff-lsp
nvimlint.linters_by_ft = {
  -- sql = { "sqlfluff" },
}

-- nvimlint.linters.sqlfluff.args = {
--   "lint",
--   "--format=json",
--   "--dialect=postgres",
-- }

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
    { name = "path" },
    { name = "luasnip" },
    { name = "nvim_lua" },
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

cmp.setup.filetype({ "sql" }, {
  sources = {
    { name = "copilot" },
    { name = "buffer" },
    { name = "luasnip" },
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
