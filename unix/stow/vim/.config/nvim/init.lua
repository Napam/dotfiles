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
    "mbbill/undotree",
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
        "nvim-lualine/lualine.nvim",
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
            { 'neovim/nvim-lspconfig' },             -- Required
            { 'williamboman/mason.nvim' },           -- Optional
            { 'williamboman/mason-lspconfig.nvim' }, -- Optional

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },     -- Required
            { 'hrsh7th/cmp-nvim-lsp' }, -- Required
            { 'L3MON4D3/LuaSnip' },     -- Required

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }
})

require "user.options"
require "user.keymaps"
require "user.nvimtree"
require "user.whichkey"
require "user.colorscheme"
require "user.lsp"

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
require("indent_blankline").setup({ show_current_context = true })

-- Treesitter
require("nvim-treesitter.configs").setup({
    auto_install = true,
    highlight = {
        enable = true
    }
})

-- Illuminate
require("illuminate").configure()

-- Lualine
require("lualine").setup()
