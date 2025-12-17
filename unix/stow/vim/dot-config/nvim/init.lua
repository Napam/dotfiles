-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out =
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("settings")

-- Get the value of the environment variable
local mode = os.getenv("LOCAL_NVIM_PLUGIN_MODE")

-- Build the spec table conditionally
local spec = {
  { import = "plugins/essentials" },
}

if mode == "ALL" then
  table.insert(spec, { import = "plugins/rest" })
end

-- Setup lazy.nvim with the conditional spec
require("lazy").setup({
  spec = spec,
  -- Configure any other settings here.
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
