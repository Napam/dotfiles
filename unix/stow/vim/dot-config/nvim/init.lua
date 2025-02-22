local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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
  "tpope/vim-fugitive",
  "stevearc/oil.nvim",
  "j-hui/fidget.nvim",
  "stevearc/conform.nvim",
  "mfussenegger/nvim-lint",
  "nanotee/sqls.nvim",
  "jake-stewart/multicursor.nvim",
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      -- Install tries to automatically detect the install method.
      -- if it fails, try calling it with one of these parameters:
      --    "curl", "wget", "bitsadmin", "go"
      require("dbee").install()
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.nvim",
    },
  },

  -- Lsp and autcompletion
  -- LSP Support
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
    },
    config = true,
  },
  { "onsails/lspkind.nvim" },

  -- Autocompletion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-nvim-lua" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "MattiasMTS/cmp-dbee" },

  -- Snippets
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    -- Lazy loaded by Comment.nvim pre_hook
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
  },
  {
    "RRethy/vim-illuminate",
    event = "User FileOpened",
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "User FileOpened",
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
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
  },
  {
    "numToStr/Comment.nvim",
    lazy = false,
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
    end,
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
  },

  -- Jupyter notebook
  -- {
  --   "kiyoon/jupynium.nvim",
  -- },
  {
    "SUSTech-data/neopyter",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter", -- neopyter don't depend on `nvim-treesitter`, but does depend on treesitter parser of python
      "AbaoFromCUG/websocket.nvim", -- for mode='direct'
    },

    ---@type neopyter.Option
    opts = {
      mode = "direct",
      remote_address = "127.0.0.1:9001",
      file_pattern = { "*.ju.*" },
      on_attach = function(bufnr)
        -- do some buffer keymap
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { desc = desc, buffer = bufnr })
        end
        -- same, recommend the former
        map("n", "<space>x", "<cmd>Neopyter execute notebook:run-cell<cr>", "run selected")
        -- map("n", "<C-Enter>", "<cmd>Neopyter run current<cr>", "run selected")

        -- same, recommend the former
        map(
          "n",
          "<space>X",
          "<cmd>Neopyter execute notebook:run-all-above<cr>",
          "run all above cell"
        )
        -- map("n", "<space>X", "<cmd>Neopyter run allAbove<cr>", "run all above cell")

        -- same, recommend the former, but the latter is silent
        map("n", "<space>nt", "<cmd>Neopyter execute kernelmenu:restart<cr>", "restart kernel")
        -- map("n", "<space>nt", "<cmd>Neopyter kernel restart<cr>", "restart kernel")

        map(
          "n",
          "<S-Enter>",
          "<cmd>Neopyter execute runmenu:run<cr>",
          "run selected and select next"
        )
        map(
          "n",
          "<M-Enter>",
          "<cmd>Neopyter execute run-cell-and-insert-below<cr>",
          "run selected and insert below"
        )

        map(
          "n",
          "<F5>",
          "<cmd>Neopyter execute notebook:restart-run-all<cr>",
          "restart kernel and run all"
        )
      end,
    },
  },
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
    char = "▏",
    tab_char = "▏",
  },
  scope = {
    enabled = true,
    show_start = false,
    char = "▎",
  },
})

-- Treesitter
require("nvim-treesitter.configs").setup({
  auto_install = true,
  highlight = {
    enable = true,
  },
  injections = {
    enable = true,
  },
  indent = {
    enable = true,
    disable = { "yaml" },
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
  ignore_install = {
    "tmux",
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
      node_decremental = "<bs>",
    },
  },

  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["ak"] = "@comment.outer",
        ["ik"] = "@comment.inner",
        ["aj"] = { query = "@cell", desc = "Select cell" },
        ["ij"] = { query = "@cellcontent", desc = "Select cell content" },
      },
    },
  },
})

-- Illuminate
require("illuminate").configure()

-- Lualine
require("lualine").setup()

-- Telescope
require("telescope").load_extension("fzf")

-- Clone the default Telescope configuration
local vimgrep_arguments = {
  table.unpack(require("telescope.config").values.vimgrep_arguments),
}

-- I want to search in hidden/dot files.
table.insert(vimgrep_arguments, "--hidden")
-- I don't want to search in the `.git` directory.
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")

require("telescope").setup({
  defaults = {
    vimgrep_arguments = vimgrep_arguments,
    mappings = {
      n = {
        ["q"] = require("telescope.actions").close,
      },
    },
  },
  pickers = {
    find_files = {
      -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
      find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
    },
  },
})

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
  under_cursor = true,
})

-- Autopairs
require("nvim-autopairs").setup({})

-- Oil
require("oil").setup({})

-- Markdown preview
vim.g.mkdp_auto_close = 0
vim.g.mkdp_refresh_slow = 1
vim.g.mkdp_preview_options = {
  mkit = {},
  katex = {},
  uml = {},
  maid = {},
  disable_sync_scroll = 0,
  sync_scroll_type = "middle",
  hide_yaml_meta = 1,
  sequence_diagrams = {},
  flowchart_diagrams = {},
  content_editable = false,
  disable_filename = 1,
  toc = {},
}

-- Fidget
require("fidget").setup({})

-- Harpoon
require("harpoon"):setup({})

-- Render-markdown
require("render-markdown").setup({})

-- Dbee
require("dbee").setup({
  sources = {
    require("dbee.sources").FileSource:new(vim.fn.getcwd() .. "/dbee.json"),
  },
})
require("cmp-dbee").setup({})

-- Multicursor
require("multicursor-nvim").setup({})
