return {
  "mfussenegger/nvim-lint",
  config = function()
    local nvim_lint = require("lint")
    local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      desc = "nvim-lint",
      group = group,
      callback = function()
        nvim_lint.try_lint()
      end,
    })
  end,
}
