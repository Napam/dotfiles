vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", {}),
  desc = "Hightlight selection on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "Search", timeout = 100 })
  end,
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

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.tfvars" },
  callback = function()
    vim.bo.filetype = "terraform"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "Dockerfile.*" },
  callback = function()
    vim.bo.filetype = "Dockerfile"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.postcss" },
  callback = function()
    vim.bo.filetype = "css"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.spec" },
  callback = function()
    vim.bo.filetype = "python"
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  command = "checktime",
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  command = [[%s/\s\+$//e]],
})
