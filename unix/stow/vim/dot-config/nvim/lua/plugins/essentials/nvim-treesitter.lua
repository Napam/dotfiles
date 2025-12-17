return {
  "nvim-treesitter/nvim-treesitter",
  branch= "master",
  lazy = false,
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  build = ":TSUpdate",
  config = function()
    local tsconfigs = require("nvim-treesitter.configs")
    tsconfigs.setup({
      sync_install = false,
      modules = {},
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
        "bash",
        "comment",
        "go",
        "graphql",
        "helm",
        "html",
        "javascript",
        "jsdoc",
        "jsonc",
        "lua",
        "markdown_inline",
        "markdown",
        "python",
        "query",
        "regex",
        "sql",
        "templ",
        "terraform",
        "typescript",
        "yaml",
        "zig",
        "r",
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
  end,
}
