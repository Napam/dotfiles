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
  "RRethy/vim-illuminate",
  "akinsho/bufferline.nvim",
  "folke/which-key.nvim",
  "lewis6991/gitsigns.nvim",
  "lukas-reineke/indent-blankline.nvim",
  "mbbill/undotree",
  "nvim-treesitter/nvim-treesitter",
  "sainnhe/sonokai",
  "tpope/vim-surround",
  "RRethy/vim-illuminate",
  "ahmedkhalf/project.nvim",
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
  },
  {
    "numToStr/Comment.nvim",
    lazy = false,
  },

  -- Lsp and autcompletion
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v2.x",
    dependencies = {
      -- LSP Support
      { "neovim/nvim-lspconfig" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },

      -- Autocompletion
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-buffer" },

      -- Snippets
      { "L3MON4D3/LuaSnip" },
      { "saadparwaiz1/cmp_luasnip" },
      { "rafamadriz/friendly-snippets" },
    },
  },

  -- Copilot
  {
    "zbirenbaum/copilot-cmp",
    event = "InsertEnter",
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      vim.defer_fn(function()
        require("copilot").setup()
        require("copilot_cmp").setup()
      end, 100)
    end,
  },

  -- Autopairs
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
  }
})

require("user.options")
require("user.keymaps")
require("user.nvimtree")
require("user.whichkey")
require("user.colorscheme")
require("user.lsp")
require("user.autocommands")

-- Bufferline
require("bufferline").setup({
  options = {
    offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
  },
})

-- Comment
require("Comment").setup()

-- Git signs
require("gitsigns").setup()

-- Blankline
require("ibl").setup({})

-- Treesitter
require("nvim-treesitter.configs").setup({
  auto_install = true,
  highlight = {
    enable = true,
  },
})

-- Illuminate
require("illuminate").configure()

-- Lualine
require("lualine").setup()

-- Telescope
require("telescope").load_extension("fzf")

-- Project nvim
require("project_nvim").setup({
  detection_methods = { "pattern" },
  patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "pom.xml" },
})

-- Illuminate
require("illuminate").configure({
  providers = {
    "lsp",
    "treesitter",
    "regex",
  },
  delay = 120,
  under_cursor = true
})

-- Autopairs
require('nvim-autopairs').setup({})
