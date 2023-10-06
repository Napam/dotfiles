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
  "mbbill/undotree",
  "sainnhe/sonokai",
  "tpope/vim-surround",
  "ahmedkhalf/project.nvim",
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    -- Lazy loaded by Comment.nvim pre_hook
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
  },
  {
    "RRethy/vim-illuminate",
    event = "User FileOpened"
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "User FileOpened"
  },
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
    branch = "v3.x",
    dependencies = {
      -- LSP Support
      { "neovim/nvim-lspconfig" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },

      -- Autocompletion
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp" },

      -- Snippets
      { "L3MON4D3/LuaSnip" },
      { "saadparwaiz1/cmp_luasnip" },
      { "rafamadriz/friendly-snippets" },
    },
  },

  -- Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup()
    end,
  },

  {
    "zbirenbaum/copilot-cmp",
    config = function()
      require("copilot_cmp").setup()
    end
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
require("user.commands")

-- Bufferline
require("bufferline").setup({
  options = {
    offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
  },
})

-- Comment
require("Comment").setup({
  pre_hook = function(...)
    local loaded, ts_comment = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
    if loaded and ts_comment then
      return ts_comment.create_pre_hook()(...)
    end
  end,
})

-- Git signs
require("gitsigns").setup()

-- Blankline
require("ibl").setup({
  indent = {
    char = "▏"
  },
  scope = {
    enabled = true,
    show_start = false,
    char = "▎"
  }
})

-- Treesitter
require("nvim-treesitter.configs").setup({
  auto_install = true,
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
    disable = { "yaml", "python" },
  },
  ensure_installed = {
    "comment",
    "markdown_inline",
    "regex",
    "typescript",
    "python",
    "bash",
    "javascript",
    "html",
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental =false,
      node_decremental ="<bs>",
    },
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
  patterns = {
    ".git",
  },
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
