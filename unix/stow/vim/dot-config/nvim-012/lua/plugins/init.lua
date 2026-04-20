---@param repo string
---@return string
_G.gh = function(repo)
  return "https://github.com/" .. repo
end

_G.vpa = function(repo)
  vim.pack.add({ gh(repo) }, { confirm = false })
end

require("plugins.ui")

vim.pack.add({
  gh('neovim/nvim-lspconfig'),
})
