require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/refractalize/oil-git-status.nvim" },
  })

  require("oil-git-status").setup({})

  -- Override bg to transparent while keeping diagnostic fg colors.
  -- Setup() links OilGitStatusIndex -> DiagnosticSignInfo and
  -- OilGitStatusWorkingTree -> DiagnosticSignWarn with default=true.
  -- Those links are now active; setting explicit fg+bg=NONE on the
  -- intermediate groups unlinks them from the diagnostic groups but
  -- preserves the fg for all leaf groups linked to them.
  local function fix_oil_status_bg()
    local diag_info = vim.api.nvim_get_hl(0, { name = "DiagnosticSignInfo", link = false })
    local diag_warn = vim.api.nvim_get_hl(0, { name = "DiagnosticSignWarn", link = false })
    local default_fg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg
    vim.api.nvim_set_hl(0, "OilGitStatusIndex", { fg = diag_info.fg or default_fg, bg = "NONE" })
    vim.api.nvim_set_hl(0, "OilGitStatusWorkingTree", { fg = diag_warn.fg or default_fg, bg = "NONE" })
  end
  fix_oil_status_bg()

  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = fix_oil_status_bg,
  })
end)
