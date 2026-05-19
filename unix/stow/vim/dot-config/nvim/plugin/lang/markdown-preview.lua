-- WARN: build hook runs upstream app/install.sh to fetch a pre-built binary.
-- Without it, plugin falls back to `node app/index.js` which needs `tslib` that
-- install.sh does not provide.
if Config.only_essential_plugins() then return end

local pack_build = require("pack_build")

local PACK_NAME = "markdown-preview.nvim"
local BIN_GLOB = "bin/markdown-preview-*"

local ensure = pack_build.setup(PACK_NAME, "app", { check_binary = BIN_GLOB })

-- WARN: set g:mkdp_filetypes BEFORE vim.pack.add. mkdp.vim guards with
-- `if !exists(...)` so a later assignment is ignored.
vim.g.mkdp_filetypes = { "markdown" }

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/iamcco/markdown-preview.nvim" },
  })

  ensure()

  -- WARN: mkdp registers `:MarkdownPreview` as a -buffer command via a
  -- BufEnter,FileType autocmd installed when its plugin file sources. Since
  -- we load it at VimEnter (after FileType/BufEnter have already fired for
  -- the startup buffer), re-fire FileType so the command attaches to it.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local ft = vim.bo[buf].filetype
      if ft == "markdown" then
        -- WARN: `buffer` and `pattern` are mutually exclusive in nvim_exec_autocmds.
        -- Use `buffer` only; mkdp's `FileType markdown` autocmd matches because
        -- this buffer's filetype is already "markdown".
        vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
      end
    end
  end
end)
