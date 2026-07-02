vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
-- WARN: runtime javascript ftplugin sets textwidth=78; zero it so Vim doesn't
-- auto-wrap -- Prettier/formatter owns line width. (Keeps .js == .jsx/.tsx.)
vim.bo.textwidth = 0
