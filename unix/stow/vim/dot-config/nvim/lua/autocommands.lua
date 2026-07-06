local UserGroup = vim.api.nvim_create_augroup("UserGroup", {})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = UserGroup,
  desc = "Hightlight selection on yank",
  pattern = "*",
  callback = function()
    vim.hl.on_yank({ higroup = "Search", timeout = 100 })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  desc = "Remove trailing whitespaces before save",
  pattern = { "*" },
  command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
  group = UserGroup,
  desc = "Advertise server socket so external programs can target the latest-focused nvim",
  callback = function()
    -- Skip empty names so a server-less instance can't clobber a live pointer.
    if vim.v.servername ~= "" then
      pcall(vim.fn.writefile, { vim.v.servername }, vim.fn.stdpath("cache") .. "/server")
    end
  end,
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
    ".localrc",
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

-- Default foldexpr to treesitter when a parser is available.
-- LSP foldingRange overrides this per-window on attach (plugin/lsp.lua).
vim.api.nvim_create_autocmd("FileType", {
  group = UserGroup,
  desc = "Set treesitter foldexpr when parser available",
  callback = function(args)
    if pcall(vim.treesitter.get_parser, args.buf) then
      for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
        -- WARN: don't clobber LSP foldexpr if already set on this window.
        if vim.wo[win].foldexpr ~= "v:lua.vim.lsp.foldexpr()" then
          require("fold").treesitter_foldexpr(win)
        end
      end
    end
  end,
})

local root_cache = {}

local default_names = {
  ".git",
  ".hg",
  ".svn",
  -- VCS: checked first, so repo root always wins in monorepos
  ".root", -- manual escape hatch
  -- Fallbacks below apply only to files with no VCS root above them:
  "go.mod",
  "pyproject.toml",
  "package.json",
  "Cargo.toml",
  "typst.toml",
  "Makefile",
  ".editorconfig",
}

-- Directories at or above $HOME are never valid project roots. Stow symlinks
-- like ~/.editorconfig and ~/.gitconfig match the marker list, so a buffer with
-- no closer marker would otherwise resolve its root to $HOME and every picker
-- (file search, grep) would scan all of home.
local home = vim.fs.normalize(vim.uv.os_homedir() or vim.fn.expand("~"))
local is_home_or_above = function(dir)
  dir = vim.fs.normalize(dir)
  if dir == home then
    return true
  end
  local prefix = dir == "/" and "/" or dir .. "/"
  return vim.startswith(home, prefix)
end

local find_root = function(buf_id, names)
  buf_id = buf_id or 0

  -- Invalid buffer → bail rather than let nvim_buf_get_name error.
  if not vim.api.nvim_buf_is_valid(buf_id) then
    return
  end

  names = names or default_names
  if type(names) == "string" then
    names = { names }
  end

  local cwd = vim.uv.cwd()

  -- Special/URI buffers (oil://, fugitive://, term://, help, etc.) have no
  -- real filesystem path. Don't walk garbage — use cwd as the search origin.
  local source_path = ""
  if vim.bo[buf_id].buftype == "" then
    source_path = vim.api.nvim_buf_get_name(buf_id)
  end

  local origin = #source_path > 0 and source_path or cwd
  if origin == nil then
    return
  end

  -- Resolve symlinks so a symlinked worktree keys/roots to its real location.
  -- realpath only succeeds for existing paths; fall back to the raw origin.
  origin = vim.uv.fs_realpath(origin) or origin

  -- names is a flat list (order = priority), so concat is a safe cache key.
  -- If you ever switch to nested priority groups, use vim.inspect(names) here.
  local key = origin .. "\0" .. table.concat(names, "\0")
  local cached = root_cache[key]
  if cached ~= nil then
    return cached
  end

  -- Marker-based root. Reject anything that escaped up to $HOME or above, then
  -- fall back to the origin's own dir: the dir itself for directory buffers
  -- (e.g. a file explorer or container dir), the parent dir for file buffers.
  local root = vim.fs.root(origin, names)
  if type(root) == "string" and is_home_or_above(root) then
    root = nil
  end
  if type(root) ~= "string" then
    if #source_path > 0 then
      root = vim.fn.isdirectory(origin) == 1 and origin or vim.fs.dirname(origin)
    else
      root = cwd
    end
  end
  if type(root) ~= "string" then
    return
  end

  root = vim.fs.normalize(vim.fn.fnamemodify(root, ":p"))
  if vim.fn.isdirectory(root) == 0 then
    return
  end

  root_cache[key] = root
  return root
end

vim.o.autochdir = false

local set_root = function(data)
  local root = find_root(data.buf)
  if root == nil then
    return
  end
  -- WARN: avoid firing DirChanged on every BufEnter within the same project.
  if root == vim.uv.cwd() then
    return
  end
  vim.fn.chdir(root)
end

local augroup = vim.api.nvim_create_augroup("AutoRoot", {})
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup,
  nested = true,
  callback = set_root,
  desc = "Find root and change current directory",
})
