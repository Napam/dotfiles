local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap
--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Move current line up and down
keymap("n", "<A-k>", ":m .-2<CR>==", opts)
keymap("n", "<A-j>", ":m .+1<CR>==", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- leader o to enter new line below without going into insert mode
keymap("n", "<leader>o", "o<ESC>", opts)

-- remove highlight
keymap("n", "<A-h>", "<CMD>noh<CR>", opts)

keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("n", "<C-d>", "<C-d>zz", opts)

-- Insert --
-- Press jk fast to change to normal mode
keymap("i", "jk", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
-- Dont copy to clipboard when pasting
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- -- Multicursor
-- local mc = require("multicursor-nvim")
--
-- -- Add cursors above/below the main cursor.
-- vim.keymap.set({ "n", "v" }, "<up>", function()
--   mc.addCursor("k")
-- end)
-- vim.keymap.set({ "n", "v" }, "<down>", function()
--   mc.addCursor("j")
-- end)
--
-- -- Add a cursor and jump to the next word under cursor.
-- vim.keymap.set({ "n", "v" }, "<c-n>", function()
--   mc.addCursor("*")
-- end)
--
-- -- Jump to the next word under cursor but do not add a cursor.
-- vim.keymap.set({ "n", "v" }, "<c-s>", function()
--   mc.skipCursor("*")
-- end)
--
-- -- Rotate the main cursor.
-- vim.keymap.set({ "n", "v" }, "<left>", mc.nextCursor)
-- vim.keymap.set({ "n", "v" }, "<right>", mc.prevCursor)
--
-- -- Delete the main cursor.
-- vim.keymap.set({ "n", "v" }, "<leader>x", mc.deleteCursor)
--
-- -- Add and remove cursors with control + left click.
-- vim.keymap.set("n", "<c-leftmouse>", mc.handleMouse)
--
-- vim.keymap.set({ "n", "v" }, "<c-q>", function()
--   if mc.cursorsEnabled() then
--     -- Stop other cursors from moving.
--     -- This allows you to reposition the main cursor.
--     mc.disableCursors()
--   else
--     mc.addCursor()
--   end
-- end)
--
-- vim.keymap.set("n", "<esc>", function()
--   if not mc.cursorsEnabled() then
--     mc.enableCursors()
--   elseif mc.hasCursors() then
--     mc.clearCursors()
--   else
--     -- Default <esc> handler.
--   end
-- end)
--
-- -- Align cursor columns.
-- vim.keymap.set("n", "<leader>a", mc.alignCursors)
--
-- -- Split visual selections by regex.
-- vim.keymap.set("v", "s", mc.splitCursors)
--
-- -- Append/insert for each line of visual selections.
-- vim.keymap.set("v", "I", mc.insertVisual)
-- vim.keymap.set("v", "A", mc.appendVisual)
--
-- -- match new cursors within visual selections by regex.
-- vim.keymap.set("v", "M", mc.matchCursors)
--
-- -- Rotate visual selection contents.
-- vim.keymap.set("v", "<leader>t", function()
--   mc.transposeCursors(1)
-- end)
-- vim.keymap.set("v", "<leader>T", function()
--   mc.transposeCursors(-1)
-- end)
--
-- Customize how cursors look.
-- vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "Cursor" })
-- vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
-- vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
-- vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
