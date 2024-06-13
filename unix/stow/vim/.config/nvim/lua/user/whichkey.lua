local which_key = require("which-key")
local harpoon = require("harpoon")

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
    j = { "<cmd>Gitsigns next_hunk<cr>", "Next hunk" },
    k = { "<cmd>Gitsigns prev_hunk<cr>", "Previous hunk" },
  },
  h = {
    name = "Harpoon",
    l = {
      function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      "List",
    },
    a = {
      function()
        harpoon:list():add()
      end,
      "Append current file",
    },
    j = {
      function()
        harpoon:list():next()
      end,
      "Harpoon next",
    },
    k = {
      function()
        harpoon:list():prev()
      end,
      "Harpoon previous",
    },
    ["1"] = {
      function()
        harpoon:list():select(1)
      end,
      "Harpoon 1",
    },
    ["2"] = {
      function()
        harpoon:list():select(2)
      end,
      "Harpoon 2",
    },
    ["3"] = {
      function()
        harpoon:list():select(3)
      end,
      "Harpoon 3",
    },
    ["4"] = {
      function()
        harpoon:list():select(4)
      end,
      "Harpoon 4",
    },
    ["5"] = {
      function()
        harpoon:list():select(5)
      end,
      "Harpoon 5",
    },
  },
  l = {
    name = "LSP",
    a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action" },
    f = {
      function()
        require("conform").format({ bufnr = vim.api.nvim_get_current_buf(), lsp_fallback = true })
      end,
      "Format",
    },
    j = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next problem" },
    k = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Previous problem" },
    l = { "<cmd>lua vim.diagnostic.open_float()<cr>", "Show problem" },
    r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
    s = { "<cmd>lua vim.lsp.buf.signature_help()<cr>", "Signature help" },
    R = {
      function()
        vim.cmd("LspStop")
        vim.cmd("LspStart")
      end,
      "Restart LSP",
    },
  },
  q = { "<cmd>q!<cr>", "Quit buffer" },
  r = { "<cmd>Telescope oldfiles<cr>", "Recent files" },
  u = { "<cmd>UndotreeToggle<cr>", "Undo history" },
  w = { "<cmd>w<cr>", "Save" },
  W = { "<cmd>wa<cr>", "Save all" },
}

which_key.setup()
which_key.register(mappings, { prefix = "<leader>" })
