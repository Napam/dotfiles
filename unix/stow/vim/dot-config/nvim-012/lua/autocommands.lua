local UserGroup = vim.api.nvim_create_augroup("UserGroup", {})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = UserGroup,
  desc = "Hightlight selection on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "Search", timeout = 100 })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  desc = "Remove trailing whitespaces before save",
  pattern = { "*" },
  command = [[%s/\s\+$//e]],
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
    ".localrc"
  },
  callback = function()
    vim.bo.filetype = "sh"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "**/.vscode/launch.json",
  },
  callback = function()
    vim.bo.filetype = "json5"
  end,
})

local root_cache = {}

local find_root = function(buf_id, names)
  buf_id = buf_id or 0
  names = names or { '.git', 'Makefile' }

  local source_path = vim.api.nvim_buf_get_name(buf_id)
  local cwd = vim.uv.cwd()

  -- Unnamed buffer: fall back to cwd. Named buffer: use the buffer's path.
  if #source_path == 0 then
    if cwd == nil then return end
    source_path = cwd
  end

  local result = root_cache[source_path]
  if result ~= nil then return result end

  result = vim.fs.root(source_path, names)

  -- Use absolute path to an existing directory
  if type(result) ~= 'string' then return end
  result = vim.fs.normalize(vim.fn.fnamemodify(result, ':p'))
  if vim.fn.isdirectory(result) == 0 then return end

  root_cache[source_path] = result

  return result
end


-- Disable conflicting option
vim.o.autochdir = false

-- Create autocommand
local set_root = function(data)
  local root = find_root(data.buf)
  if root == nil then return end
  -- Avoid firing DirChanged on every BufEnter within the same project.
  if root == vim.uv.cwd() then return end
  vim.fn.chdir(root)
end

local augroup = vim.api.nvim_create_augroup('AutoRoot', {})
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup,
  nested = true,
  callback = set_root,
  desc = 'Find root and change current directory'
})
