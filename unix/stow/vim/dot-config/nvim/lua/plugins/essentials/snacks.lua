return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    animate = { enabled = false },
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    words = { enabled = true },
    zen = { enabled = true },

    image = {
      enabled = true,
      doc = {
        max_width = 80,
        max_height = 40,
        inline = false,
        float = false
      }
    },

    picker = {
      enabled = true,
      sources = {
        files = {
          hidden = true,
          ignored = true,
          exclude = {
            ".git",
            "node_modules",
            ".DS_Store",
            ".venv",
            "__pycache__"
          },
        },
        grep = {
          hidden = true,
          ignored = true,
          exclude = {
            ".git",
            "node_modules",
            ".DS_Store",
            ".venv",
            "__pycache__"
          },
        },
      },
      win = {
        input = {
          keys = {
            ["<C-y>"] = { "confirm", mode = { "n", "i" } }
          }
        }
      }
    },

    lazygit = {
      configure = true,
      theme = {
        [241]                      = { fg = "Special" },
        activeBorderColor          = { fg = "MatchParen", bold = true },
        cherryPickedCommitBgColor  = { fg = "Identifier" },
        cherryPickedCommitFgColor  = { fg = "Function" },
        defaultFgColor             = { fg = "Normal" },
        inactiveBorderColor        = { fg = "FloatBorder" },
        optionsTextColor           = { fg = "Function" },
        searchingActiveBorderColor = { fg = "MatchParen", bold = true },
        selectedLineBgColor        = { bg = "Visual" }, -- set to `default` to have no background colour
        unstagedChangesColor       = { fg = "DiagnosticError" },
      },
      win = {
        style = "lazygit",
      },
    },

    styles = {
      input = {
        relative = "cursor",
      },
      zen = {
        width = 160,
      },
    },

  },
}
