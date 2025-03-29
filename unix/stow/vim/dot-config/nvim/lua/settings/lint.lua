local nvimlint = require('lint')

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  callback = function()
    nvimlint.try_lint()
  end,
})
