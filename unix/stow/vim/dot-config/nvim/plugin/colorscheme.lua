vim.pack.add({
  { src = "https://github.com/sainnhe/sonokai" },
  { src = "https://github.com/rebelot/kanagawa.nvim" },
})

vim.cmd([[
    au ColorScheme * hi GitSignsAdd ctermbg=none guibg=none
    au ColorScheme * hi GitSignsChange ctermbg=none guibg=none
    au ColorScheme * hi GitSignsChangeDelete ctermbg=none guibg=none
    au ColorScheme * hi GitSignsDelete ctermbg=none guibg=none
    au ColorScheme * hi GitSignsTopDelete ctermbg=none guibg=none
    au ColorScheme * hi GitSignsUntracked ctermbg=none guibg=none
    au ColorScheme * hi LineNr ctermbg=none guibg=none
    au ColorScheme * hi Normal ctermbg=none guibg=none
    au ColorScheme * hi NormalNC ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeEndOfBuffer ctermbg=none guibg=none
    au ColorScheme * hi NvimTreeNormal ctermbg=none guibg=none
    au ColorScheme * hi SignColumn ctermbg=none guibg=none
    au ColorScheme * hi TelescopeBorder ctermbg=none guibg=none
  ]])

vim.cmd.colorscheme("kanagawa-wave")
