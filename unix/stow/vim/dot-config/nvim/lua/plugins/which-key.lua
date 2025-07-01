local mappings = {
  { "gd", "<cmd>lua Snacks.picker.lsp_definitions()<cr>",      desc = "Goto Definition" },
  { "gD", "<cmd>lua Snacks.picker.lsp_declarations()<cr>",     desc = "Goto Declaration" },
  { "gr", "<cmd>lua Snacks.picker.lsp_references()<cr>",       nowait = true,                  desc = "References" },
  { "gI", "<cmd>lua Snacks.picker.lsp_implementations()<cr>",  desc = "Goto Implementation" },
  { "gy", "<cmd>lua Snacks.picker.lsp_type_definitions()<cr>", desc = "Goto T[y]pe Definition" },
  {
    "s",
    mode = { "n", "x", "o" },
    function() require("flash").jump() end,
    desc = "Flash"
  },

  { "<leader>C",  "<cmd>edit ~/.config/nvim/init.lua<cr>",  desc = "Open config" },
  { "<leader>W",  "<cmd>wa<cr>",                            desc = "Save all" },
  { "<leader>c",  "<cmd>lua Snacks.bufdelete()<cr>",        desc = "Close buffer" },
  { "<leader>e",  "<cmd>Oil<cr>",                           desc = "File explorer" },
  { "<leader>q",  "<cmd>q!<cr>",                            desc = "Quit buffer" },
  { "<leader>w",  "<cmd>w<cr>",                             desc = "Save" },

  { "<leader>f",  group = "Find" },
  { "<leader>fb", "<cmd>lua Snacks.picker.buffers()<cr>",   desc = "Find in buffers" },
  { "<leader>ff", "<cmd>lua Snacks.picker.files()<cr>",     desc = "Find files" },
  { "<leader>fg", "<cmd>lua Snacks.picker.grep()<cr>",      desc = "Find in files" },
  { "<leader>fo", "<cmd>lua Snacks.picker.recent()<cr>",    desc = "Recently used files" },
  { "<leader>fr", "<cmd>lua Snacks.picker.resume()<cr>",    desc = "Resume finder" },
  { "<leader>fs", "<cmd>lua Snacks.picker.smart()<cr>",     desc = "Smart file serach" },
  { "<leader>fu", "<cmd>lua Snacks.picker.undo()<cr>",      desc = "Undo list" },

  { "<leader>g",  group = "Git" },
  { "<leader>gB", "<cmd>Git blame<cr>",                     desc = "File blame" },
  { "<leader>gb", "<cmd>Gitsigns blame_line<cr>",           desc = "Line blame" },
  { "<leader>gg", "<cmd>lua Snacks.lazygit()<cr>",          desc = "Git client" },
  { "<leader>gj", "<cmd>Gitsigns next_hunk<cr>",            desc = "Next hunk" },
  { "<leader>gk", "<cmd>Gitsigns prev_hunk<cr>",            desc = "Previous hunk" },
  { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>",           desc = "Reset hunk" },

  { "<leader>l",  group = "LSP" },
  { "<leader>lR", "<cmd>LspRestart<cr>",                    desc = "Restart LSP" },
  { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code action" },
  { "<leader>ld", "<cmd>Telescope diagnostics<cr>",         desc = "Open telescope diagnostics" },
  {
    "<leader>lf",
    function()
      require("conform").format({ bufnr = vim.api.nvim_get_current_buf(), lsp_fallback = true })
    end,
    desc = "Format",
  },
  { "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<cr>",                   desc = "Next problem" },
  { "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<cr>",                   desc = "Previous problem" },
  { "<leader>ll", "<cmd>lua vim.diagnostic.open_float()<cr>",                  desc = "Show problem" },
  { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>",                         desc = "Rename" },
  { "<leader>ls", "<cmd>lua vim.lsp.buf.signature_help()<cr>",                 desc = "Signature help" },

  { "<leader>p",  group = "Persistence" },
  { "<leader>ps", function() require("persistence").load() end,                desc = "Load the session for the current directory" },
  { "<leader>pS", function() require("persistence").select() end,              desc = "Select a session to load" },
  { "<leader>pl", function() require("persistence").load({ last = true }) end, desc = "Load the last session" },
  { "<leader>pd", function() require("persistence").stop() end,                desc = "Stop persistence" },

  { "<leader>x",  group = "Extra diagnostics" },
  {
    "<leader>xx",
    "<cmd>Trouble diagnostics toggle<cr>",
    desc = "Diagnostics (Trouble)",
  },
  {
    "<leader>xX",
    "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
    desc = "Buffer Diagnostics (Trouble)",
  },
  {
    "<leader>xs",
    "<cmd>Trouble symbols toggle focus=false<cr>",
    desc = "Symbols (Trouble)",
  },
  {
    "<leader>xl",
    "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
    desc = "LSP Definitions / references / ... (Trouble)",
  },
  {
    "<leader>xL",
    "<cmd>Trouble loclist toggle<cr>",
    desc = "Location List (Trouble)",
  },
  {
    "<leader>xQ",
    "<cmd>Trouble qflist toggle<cr>",
    desc = "Quickfix List (Trouble)",
  },

  { "<leader>S",  group = "Snacks" },
  { "<leader>Sz", "<cmd>lua Snacks.zen()<cr>",                          desc = "Enable zen" },
  { "<leader>Sn", "<cmd>lua Snacks.notifier.show_history()<cr>",        desc = "Notification history" },

  { "<leader>j",  group = "Jupyter" },
  { "<leader>jc", "<cmd>Neopyter execute notebook:run-cell<cr>",        desc = "Run selected cell" },
  { "<leader>js", "<cmd>Neopyter sync current<cr>",                     desc = "Sync" },
  { "<leader>ja", "<cmd>Neopyter execute notebook:run-all-above<cr>",   desc = "Run all above" },
  { "<leader>jb", "<cmd>Neopyter execute notebook:run-all-below<cr>",   desc = "Run all below" },
  { "<leader>jA", "<cmd>Neopyter execute runmenu:run-all<cr>",          desc = "Run all" },
  { "<leader>jr", "<cmd>Neopyter execute kernelmenu:restart<cr>",       desc = "Restart" },
  { "<leader>jR", "<cmd>Neopyter execute notebook:restart-run-all<cr>", desc = "Restart and run all" },
}

return {
  "folke/which-key.nvim",
  opts = {
    defaults = {},
    spec = mappings,
  },
}
