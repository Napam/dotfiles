vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks.setup({
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

  dashboard = {
    enabled = true,
    preset = {
      keys = {
        { icon = " ", key = "n", desc = "New File",          action = ":ene | startinsert" },
        { icon = " ", key = "r", desc = "Recent Files",      action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "s", desc = "Restore Session",   action = ":lua require('persistence').load()" },
        { icon = " ", key = "u", desc = "Check for Updates", action = ":Pack check" },
        { icon = " ", key = "q", desc = "Quit",              action = ":qa" },
      },
      header = [[
 .          .
 ';;,.        ::'
 ,:::;,,        :ccc,
,::c::,,,,.     :cccc,
,cccc:;;;;;.    cllll,
,cccc;.;;;;;,   cllll;
:cccc; .;;;;;;. coooo;
;llll;   ,:::::'loooo;
;llll:    ':::::loooo:
:oooo:     .::::llodd:
.;ooo:       ;cclooo:.
.;oc        'coo;.
 .'         .,.]],
    },
    sections = {
      { section = "header" },
      { section = "keys",  gap = 1, padding = 1 },
      function()
        local entries = require("exrc").list()
        if #entries == 0 then
          return { text = "" }
        end
        local suffix = {
          trusted = "",
          modified = " (modified — re-run :trust)",
          denied = " (denied)",
          untrusted = " (untrusted — run :trust)",
        }
        local lines = {}
        for _, e in ipairs(entries) do
          table.insert(lines, "  " .. e.path .. (suffix[e.status] or ""))
        end
        return {
          text = table.concat(lines, "\n"),
          align = "center",
          hl = "Comment",
          padding = 1,
        }
      end,
      function()
        if not _G._nvim_startup_ms then
          _G._nvim_startup_ms = Config.nvim_start_time
              and string.format("%.2f", (vim.uv.hrtime() - Config.nvim_start_time) / 1e6)
              or "?"
        end
        local ms = _G._nvim_startup_ms
        local plugin_count = #vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/*/*", false, true)
        return {
          align = "center",
          text = {
            { "⚡ Neovim started with ", hl = "footer" },
            { tostring(plugin_count), hl = "special" },
            { " plugins in ", hl = "footer" },
            { ms .. "ms", hl = "special" },
          },
        }
      end,
    },
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
