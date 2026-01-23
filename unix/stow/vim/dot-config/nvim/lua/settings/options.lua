vim.opt.clipboard = "unnamedplus" -- access system clipboard
vim.opt.conceallevel = 0          -- so that `` is visible in markdown files
vim.opt.cursorline = false        -- highlight current line
vim.opt.expandtab = true          -- convert tabs to spaces
vim.opt.ignorecase = true         -- ignore case in search patterns
vim.opt.list = true               -- show listchars, such as whitespace
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.signcolumn = "yes" -- always show signcolumns or you will get janky stuff
vim.opt.softtabstop = 4
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.updatetime = 100
vim.opt.wrap = false
vim.opt.scrolloff = 5
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- This is important to set to use with nvim-ufo
vim.o.foldcolumn = '0'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.exrc = true
