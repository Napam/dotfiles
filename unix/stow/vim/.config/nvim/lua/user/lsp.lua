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
    }
})

local lsp = require('lsp-zero').preset({})

lsp.on_attach(function(_, bufnr)
    lsp.default_keymaps({ buffer = bufnr })

    vim.keymap.set('n', 'gr', '<cmd>Telescope lsp_references<cr>', { buffer = true })
end)

lsp.setup()

local cmp = require("cmp")

cmp.setup({
    mapping = {
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        ['<TAB>'] = cmp.mapping.select_next_item(),
        ['<S-TAB>'] = cmp.mapping.select_prev_item(),
    }
})
