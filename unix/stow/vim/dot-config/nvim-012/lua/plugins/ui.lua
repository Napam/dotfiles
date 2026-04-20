vpa('sainnhe/sonokai')

vim.cmd(
  [[
    au ColorScheme * hi Normal ctermbg=none guibg=none
    au ColorScheme * hi SignColumn ctermbg=none guibg=none
    au ColorScheme * hi NormalNC ctermbg=none guibg=none
    au ColorScheme * hi MsgArea ctermbg=none guibg=none
    au ColorScheme * hi TelescopeBorder ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeNormal ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeEndOfBuffer ctermbg=none guibg=none
  ]]
)

vim.cmd.colorscheme("sonokai")

vpa('folke/snacks.nvim')

local snacks = require('snacks')
snacks.setup({
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
})
