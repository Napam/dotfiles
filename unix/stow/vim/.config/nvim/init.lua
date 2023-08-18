local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    "folke/which-key.nvim",
    "sainnhe/sonokai",
    "akinsho/bufferline.nvim",
    "lewis6991/gitsigns.nvim",
    "lukas-reineke/indent-blankline.nvim",
    "nvim-treesitter/nvim-treesitter",
    "RRethy/vim-illuminate",
    {
        "kdheepak/lazygit.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim"
        }
    },
    {
        "nvim-tree/nvim-tree.lua",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons"
        }
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {
        'numToStr/Comment.nvim',
        lazy = false
    },

    -- Lsp and autcompletion
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }
})

require "user.options"
require "user.keymaps"

-- colorscheme
vim.cmd [[
    au ColorScheme * hi Normal ctermbg=none guibg=none
    au ColorScheme * hi SignColumn ctermbg=none guibg=none
    au ColorScheme * hi NormalNC ctermbg=none guibg=none
    au ColorScheme * hi MsgArea ctermbg=none guibg=none
    au ColorScheme * hi TelescopeBorder ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeNormal ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeEndOfBuffer ctermbg=none guibg=none
]]

vim.cmd "colorscheme sonokai"

-- which-key
local which_key = require("which-key")
local mappings = {
    w = { "<cmd>wa<cr>", "Save all" },
    q = { "<cmd>q<cr>", "Quit buffer" },
    e = { "<cmd>NvimTreeToggle<cr>", "File explorer" },
    c = { "<cmd>bd<cr>", "Close buffer" },
    g = { "<cmd>LazyGit<cr>", "LazyGit" },
    f = {
        name = "Find",
        f = { "<cmd>Telescope find_files<cr>", "Find files" },
        r = { "<cmd>Telescope oldfiles<cr>", "Recent files" },
        g = { "<cmd>Telescope live_grep<cr>", "Find in files" },
        b = { "<cmd>Telescope buffers<cr>", "Find buffers" }
    },
}

which_key.setup()
which_key.register(mappings, { prefix = "<leader>" })

-- Nvimtree
vim.g.loaded_netrw = 1
vim.g.netrwPlugin = 1
vim.opt.termguicolors = true

local nvim_tree = require "nvim-tree"

local function nv_on_attach(bufnr)
    local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    local api = require "nvim-tree.api"
    api.config.mappings.default_on_attach(bufnr)
    vim.keymap.set('n', 'l', api.node.open.edit, opts("Open: Edit"))
    vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts("Close Directory"))
end

nvim_tree.setup({ on_attach = nv_on_attach })

-- Bufferline
require("bufferline").setup({
    options = {
        offsets = { { filetype = "NvimTree", text = "", padding = 1 } }
    }
})

-- Comment
require("Comment").setup()

-- Git signs
require("gitsigns").setup()

-- Blankline
require("indent_blankline").setup({
    show_current_context = true,
    show_current_context_start = true,
})

-- Treesitter
require("nvim-treesitter.configs").setup({
    auto_install = true,
    highlight = {
        enable = true
    }
})

-- Illuminate
require("illuminate").configure()

-- Lsp stuff
require("mason").setup()
require("mason-lspconfig").setup()

local lsp = require('lsp-zero').preset({})

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({ buffer = bufnr })
end)

lsp.setup()
