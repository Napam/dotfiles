return {
  "mfussenegger/nvim-lint",
  config = function()
    local nvim_lint = require("lint")
    local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

    local pattern = '([^:]+): ([^:]+):(%d+):(%d+): (.+)'
    local groups = { 'severity', 'file', 'lnum', 'col', 'message' }

    nvim_lint.linters.alloy = {
      name = "alloy-validate",
      cmd = "alloy",
      args = { "validate" },
      stream = 'stderr',
      ignore_exitcode = true,
      parser = require("lint.parser").from_pattern(pattern, groups, nil, {
        source = "alloy-validate",
        severity = vim.diagnostic.severity.ERROR,
      })
    }

    nvim_lint.linters_by_ft = {
      alloy = { "alloy" },
    }

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      desc = "nvim-lint",
      group = group,
      callback = function()
        nvim_lint.try_lint()
      end,
    })
  end,
}
