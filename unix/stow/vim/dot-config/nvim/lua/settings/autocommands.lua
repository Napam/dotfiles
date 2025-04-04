local user_group = vim.api.nvim_create_augroup("user_group", {})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = user_group,
  desc = "Hightlight selection on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "Search", timeout = 100 })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  desc = "Remove trailing whitespaces before save",
  pattern = { "*" },
  command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    ".zshrc",
    ".bashrc",
    "*.zsh",
    "*.bash",
    "dot-zshrc",
    "dot-bashrc",
    ".env",
    ".env.*",
  },
  callback = function()
    vim.bo.filetype = "sh"
  end,
})
