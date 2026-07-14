-- WARN: for window opts use vim.wo[0][0] (= :setlocal), NOT plain vim.wo, which
-- is :set (:h vim.wo) and also writes the window's *global* copy -- the value a
-- later :edit in this window resets to and that new splits inherit, so plain
-- vim.wo.wrap leaked wrap=true onto code files opened from a markdown window.
-- Nvim remembers window-local values per buffer (:h local-options), so these
-- follow the md buffer on their own. (vim.opt* is slated for removal, neovim#20451.)
vim.wo[0][0].wrap = true
vim.wo[0][0].linebreak = true
vim.bo.textwidth = 80
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
