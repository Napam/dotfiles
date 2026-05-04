local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Window nav
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Move line
keymap("n", "<A-k>", ":m .-2<CR>==", opts)
keymap("n", "<A-j>", ":m .+1<CR>==", opts)

-- Buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

keymap("n", "<leader>o", "o<ESC>", opts)
keymap("n", "<A-h>", "<CMD>noh<CR>", opts)

keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("n", "<C-d>", "<C-d>zz", opts)

-- LSP
keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
keymap("n", "gi", "<cmd>FzfLua lsp_implementations()<cr>", opts)
keymap("n", "gr", "<cmd>FzfLua lsp_references<cr>", opts)

-- Visual: stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)

-- Don't yank on paste
keymap("v", "p", '"_dP', opts)

-- Visual block: move text
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Terminal nav disabled; conflicts with Lazygit.
-- keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", { silent = true })
-- keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", { silent = true })
-- keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", { silent = true })
-- keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", { silent = true })
-- keymap("t", "<C-n>", "<C-\\><C-N>",       { silent = true })
