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
  },
})

local lsp = require("lsp-zero").preset("recommended")
lsp.on_attach(function(_, bufnr)
  local opts = { buffer = bufnr }
  lsp.default_keymaps(opts)

  vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
  vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
end)

lsp.setup()

local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.black,
    null_ls.builtins.formatting.prettier,
  },
})

local cmp = require("cmp")

require("luasnip.loaders.from_vscode").load()

cmp.setup({
  sources = {
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "luasnip" },
  },
  mapping = {
    ['<C-Space>'] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    ["<TAB>"] = cmp.mapping.select_next_item(),
    ["<S-TAB>"] = cmp.mapping.select_prev_item(),
  },
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
