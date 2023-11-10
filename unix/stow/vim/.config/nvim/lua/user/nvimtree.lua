vim.g.loaded_netrw = 1
vim.g.netrwPlugin = 1
vim.opt.termguicolors = true

local nvim_tree = require "nvim-tree"

local function nv_on_attach(bufnr)
  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  local api = require "nvim-tree.api"
  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.set('n', 'l', api.node.open.edit, opts("Open: Edit"))
  vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts("Close Directory"))
end

nvim_tree.setup({
  on_attach = nv_on_attach,
  sync_root_with_cwd = true,
  respect_buf_cwd = true,
  view = {
    relativenumber = true,
  },
  update_focused_file = {
    enable = true,
    update_root = true
  },
})
