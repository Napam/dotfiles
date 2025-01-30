vim.cmd([[
    au ColorScheme * hi Normal ctermbg=none guibg=none
    au ColorScheme * hi SignColumn ctermbg=none guibg=none
    au ColorScheme * hi NormalNC ctermbg=none guibg=none
    au ColorScheme * hi MsgArea ctermbg=none guibg=none
    au ColorScheme * hi TelescopeBorder ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeNormal ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeEndOfBuffer ctermbg=none guibg=none
]])

vim.cmd("colorscheme sonokai")

vim.api.nvim_set_hl(0, "CmpItemKindMagic", { bg = "NONE", fg = "#D4D434" })
vim.api.nvim_set_hl(0, "CmpItemKindPath", { link = "CmpItemKindFolder" })
vim.api.nvim_set_hl(0, "CmpItemKindDictkey", { link = "CmpItemKindKeyword" })
vim.api.nvim_set_hl(0, "CmpItemKindInstance", { link = "CmpItemKindVariable" })
vim.api.nvim_set_hl(0, "CmpItemKindStatement", { link = "CmpItemKindVariable" })
