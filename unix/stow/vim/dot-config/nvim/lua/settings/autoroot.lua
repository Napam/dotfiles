-- Extracted from mini.misc

local root_cache = {}

local find_root = function(buf_id, names)
  buf_id = buf_id or 0
  names = names or { '.git', 'Makefile' }

  local source_path = vim.api.nvim_buf_get_name(buf_id)
  local cwd = vim.loop.cwd()

  if #source_path == 0 and cwd ~= nil then
    source_path = cwd
  else
    return
  end

  local result = root_cache[source_path]
  if result ~= nil then return result end

  result = vim.fs.root(vim.loop.cwd(), names)

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
  vim.fn.chdir(root)
end

local augroup = vim.api.nvim_create_augroup('AutoRoot', {})
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup,
  nested = true,
  callback = set_root,
  desc = 'Find root and change current directory'
})
