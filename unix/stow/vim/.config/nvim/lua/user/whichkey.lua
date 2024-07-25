local which_key = require("which-key")
local harpoon = require("harpoon")

local mappings = {
  { "<leader>C", "<cmd>edit ~/.config/nvim/init.lua<cr>", desc = "Open config" },
  { "<leader>E", "<cmd>Oil<cr>", desc = "File explorer editor" },
  { "<leader>W", "<cmd>wa<cr>", desc = "Save all" },
  { "<leader>c", "<cmd>BufferKill<cr>", desc = "Close buffer" },
  { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Tree file explorer" },
  { "<leader>f", group = "Find" },
  { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
  { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find in files" },
  { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume find" },
  { "<leader>g", group = "Git" },
  { "<leader>gB", "<cmd>Git blame<cr>", desc = "File blame" },
  { "<leader>gb", "<cmd>Gitsigns blame_line<cr>", desc = "Line blame" },
  { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Git client" },
  { "<leader>gj", "<cmd>Gitsigns next_hunk<cr>", desc = "Next hunk" },
  { "<leader>gk", "<cmd>Gitsigns prev_hunk<cr>", desc = "Previous hunk" },
  { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset hunk" },
  { "<leader>h", group = "Harpoon" },
  {
    "<leader>h1",
    function()
      harpoon:list():select(1)
    end,
    desc = "Harpoon 1",
  },
  {
    "<leader>h2",
    function()
      harpoon:list():select(2)
    end,
    desc = "Harpoon 2",
  },
  {
    "<leader>h3",
    function()
      harpoon:list():select(3)
    end,
    desc = "Harpoon 3",
  },
  {
    "<leader>h4",
    function()
      harpoon:list():select(4)
    end,
    desc = "Harpoon 4",
  },
  {
    "<leader>h5",
    function()
      harpoon:list():select(5)
    end,
    desc = "Harpoon 5",
  },
  {
    "<leader>ha",
    function()
      harpoon:list():add()
    end,
    desc = "Append current file",
  },
  {
    "<leader>hj",
    function()
      harpoon:list():next()
    end,
    desc = "Harpoon next",
  },
  {
    "<leader>hk",
    function()
      harpoon:list():previous()
    end,
    desc = "Harpoon previous",
  },
  {
    "<leader>hl",
    function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end,
    desc = "List",
  },
  { "<leader>l", group = "LSP" },
  { "<leader>lR", "<cmd>LspRestart<cr>", desc = "Restart LSP" },
  { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code action" },
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
  { "<leader>q", "<cmd>q!<cr>", desc = "Quit buffer" },
  { "<leader>r", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
  { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo history" },
  { "<leader>w", "<cmd>w<cr>", desc = "Save" },
}

which_key.setup()
which_key.add(mappings)
