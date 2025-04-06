-- Extracted from mini.misc

local root_cache = {}

local find_root = function(buf_id, names)
  buf_id = buf_id or 0
  names = names or { '.git', 'Makefile' }

  -- Compute directory to start search from. NOTEs on why not using file path:
  -- - This has better performance because `vim.fs.find()` is called less.
  -- - *Needs* to be a directory for callable `names` to work.
  -- - Later search is done including initial `path` if directory, so this
  --   should work for detecting buffer directory as root.
  local path = vim.api.nvim_buf_get_name(buf_id)
  if path == '' then
    path = vim.loop.cwd() or ''
  end
  local dir_path = vim.fs.dirname(path)

  -- Try using cache
  local res = root_cache[dir_path]
  if res ~= nil then return res end

  -- Find root
  local root_file = vim.fs.find(names, { path = dir_path, upward = true })[1]
  if root_file ~= nil then
    res = vim.fs.dirname(root_file)
  end

  -- Use absolute path to an existing directory
  if type(res) ~= 'string' then return end
  res = vim.fs.normalize(vim.fn.fnamemodify(res, ':p'))
  if vim.fn.isdirectory(res) == 0 then return end

  -- Cache result per directory path
  root_cache[dir_path] = res

  return res
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
