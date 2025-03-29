local mappings = {
  { "<leader>C", "<cmd>edit ~/.config/nvim/init.lua<cr>", desc = "Open config" },
  { "<leader>W", "<cmd>wa<cr>", desc = "Save all" },
  { "<leader>c", "<cmd>:bd<cr>", desc = "Close buffer" },
  { "<leader>e", "<cmd>Oil<cr>", desc = "File explorer" },
  { "<leader>r", "<cmd>FzfLua oldfiles<cr>", desc = "Find old files" },
  { "<leader>q", "<cmd>q!<cr>", desc = "Quit buffer" },
  { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo history" },
  { "<leader>w", "<cmd>w<cr>", desc = "Save" },

  { "<leader>f", group = "Find" },
  { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
  { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Find in files" },
  { "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "Resume finder" },

  { "<leader>g", group = "Git" },
  { "<leader>gB", "<cmd>Git blame<cr>", desc = "File blame" },
  { "<leader>gb", "<cmd>Gitsigns blame_line<cr>", desc = "Line blame" },
  { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Git client" },
  { "<leader>gj", "<cmd>Gitsigns next_hunk<cr>", desc = "Next hunk" },
  { "<leader>gk", "<cmd>Gitsigns prev_hunk<cr>", desc = "Previous hunk" },
  { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset hunk" },

  { "<leader>l", group = "LSP" },
  { "<leader>lR", "<cmd>LspRestart<cr>", desc = "Restart LSP" },
  { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code action" },
  { "<leader>ld", "<cmd>Telescope diagnostics<cr>", desc = "Open telescope diagnostics" },
  {
    "<leader>lf",
    function()
      require("conform").format({ bufnr = vim.api.nvim_get_current_buf(), lsp_fallback = true })
    end,
    desc = "Format",
  },
  { "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<cr>", desc = "Next problem" },
  { "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<cr>", desc = "Previous problem" },
  { "<leader>ll", "<cmd>lua vim.diagnostic.open_float()<cr>", desc = "Show problem" },
  { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename" },
  { "<leader>ls", "<cmd>lua vim.lsp.buf.signature_help()<cr>", desc = "Signature help" },
}

return {
  "folke/which-key.nvim",
  opts = {
    defaults = {},
    spec = mappings,
  },
}
