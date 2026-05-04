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

-- Enable this to allow project-specific .nvim.lua files
vim.o.exrc = true

-- Required for `opts.events.reload`, opencode.nvim wants this
vim.o.autoread = true

vim.diagnostic.config({
  virtual_text = { source = true },
  float = {
    focusable = true,
    -- WARN: built-in `source = true` silently drops sources whose d.source
    -- is nil (some LSPs/linters omit it). Format inline so something always
    -- shows. Code is auto-appended by nvim as ` [code]` suffix; don't dup.
    format = function(d)
      return string.format("%s: %s", d.source or "?", d.message)
    end,
  },
})

vim.o.winborder = 'single'
