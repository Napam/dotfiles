local user_group = vim.api.nvim_create_augroup("user_group", {})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = user_group,
  desc = "Hightlight selection on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "Search", timeout = 100 })
  end,
})
