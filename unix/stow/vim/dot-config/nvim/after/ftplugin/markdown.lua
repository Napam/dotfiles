-- WARN: use setlocal-scoped accessors (vim.wo window-local, vim.bo buffer-local),
-- never vim.opt/vim.o (= :set), which also writes the window-global value that
-- other buffers and new windows inherit -- opening markdown would leak wrap=true
-- onto later-opened files. (vim.opt* is also slated for removal, neovim#20451.)
vim.wo.wrap = true
vim.wo.linebreak = true
vim.bo.textwidth = 80
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
