local which_key = require("which-key")
local mappings = {
  c = { "<cmd>BufferKill<cr>", "Close buffer" },
  C = { "<cmd>edit ~/.config/nvim/init.lua<cr>", "Open config" },
  e = { "<cmd>NvimTreeToggle<cr>", "Tree file explorer" },
  E = { "<cmd>Oil<cr>", "File explorer editor" },
  f = {
    name = "Find",
    f = { "<cmd>Telescope find_files<cr>", "Find files" },
    g = { "<cmd>Telescope live_grep<cr>", "Find in files" },
    r = { "<cmd>Telescope resume<cr>", "Resume find" },
    b = { "<cmd>Telescope buffers<cr>", "Find buffers" },
  },
  g = {
    name = "Git",
    g = { "<cmd>LazyGit<cr>", "Git client" },
    r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk" },
    b = { "<cmd>Gitsigns blame_line<cr>", "Line blame" },
    B = { "<cmd>Git blame<cr>", "File blame" },
  },
  h = { "<cmd>noh<cr>", "Remove highlights" },
  l = {
    name = "LSP",
    a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action" },
    f = { "<cmd>LspZeroFormat<cr>", "Format" },
    j = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next problem" },
    k = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Previous problem" },
    l = { "<cmd>lua vim.diagnostic.open_float()<cr>", "Show problem" },
    r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
    s = { "<cmd>lua vim.lsp.buf.signature_help()<cr>", "Signature help" },
    R = { "<cmd>LspRestart<cr>", "Restart LSP" },
  },
  q = { "<cmd>q!<cr>", "Quit buffer" },
  r = { "<cmd>Telescope oldfiles<cr>", "Recent files" },
  u = { "<cmd>UndotreeToggle<cr>", "Undo history" },
  w = { "<cmd>w<cr>", "Save" },
  W = { "<cmd>wa<cr>", "Save all" },
}

which_key.setup()
which_key.register(mappings, { prefix = "<leader>" })
