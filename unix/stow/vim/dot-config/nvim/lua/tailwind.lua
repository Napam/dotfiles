-- Tailwind language server support for maud views.
--
-- The server has no `rust` filetype, and starting it for every Rust project
-- would leave a node process running for no reason. Attach it per buffer when
-- the file contains a maud `html!` block and the project actually uses
-- Tailwind.

local M = {}

---@param path string
---@return string?
local function read(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local data = file:read("*a")
  file:close()
  return data
end

local PACKAGES = { "tailwindcss", "@tailwindcss/cli", "@tailwindcss/vite", "@tailwindcss/postcss" }

local CONFIGS = {
  ["tailwind.config.js"] = true,
  ["tailwind.config.cjs"] = true,
  ["tailwind.config.mjs"] = true,
  ["tailwind.config.ts"] = true,
  ["tailwind.config.mts"] = true,
  ["tailwind.config.cts"] = true,
}

---@param path string
---@return boolean
local function package_uses_tailwind(path)
  local data = read(path)
  if not data then
    return false
  end
  for _, name in ipairs(PACKAGES) do
    if data:find('"' .. name .. '"', 1, true) then
      return true
    end
  end
  return false
end

-- Tailwind v4 has no JS/TS config: the stylesheet entry point imports the
-- framework or declares its own theme.
---@param path string
---@return boolean
local function is_tailwind_css(path)
  local data = read(path)
  if not data then
    return false
  end
  return data:find("@import%s*['\"]tailwindcss[/'\"]") ~= nil or data:find("@theme", 1, true) ~= nil
end

---@param path string
---@param kind string
---@return boolean
local function is_file(path, kind)
  if kind == "file" then
    return true
  end
  if kind ~= "link" then
    return false
  end
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

---@param root string
---@return boolean
local function has_tailwind(root)
  -- depth 3 covers web/package.json and assets/css/input.css alike; skip
  -- returns false to prune.
  local opts = {
    depth = 3,
    follow = true,
    skip = function(dir)
      local base = vim.fs.basename(dir)
      return base ~= "node_modules" and base ~= "target" and base:sub(1, 1) ~= "."
    end,
  }
  for path, kind in vim.fs.dir(root, opts) do
    local full = root .. "/" .. path
    if is_file(full, kind) then
      local name = vim.fs.basename(path)
      if CONFIGS[name] or (name == "package.json" and package_uses_tailwind(full)) then
        return true
      end
      if name:sub(-4) == ".css" and is_tailwind_css(full) then
        return true
      end
    end
  end

  return false
end

---@param buf integer
---@return boolean
local function is_maud_view(buf)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:find("html!", 1, true) then
      return true
    end
  end
  return false
end

---@param buf integer
function M.attach(buf)
  if not vim.api.nvim_buf_is_loaded(buf) or not is_maud_view(buf) then
    return
  end

  if #vim.lsp.get_clients({ bufnr = buf, name = "tailwindcss" }) > 0 then
    return
  end

  local root = vim.fs.root(buf, { ".git" }) or vim.fs.root(buf, { "Cargo.toml" })
  if not root or not has_tailwind(root) then
    return
  end

  local config = vim.lsp.config["tailwindcss"]
  if not config then
    return
  end

  vim.lsp.start(vim.tbl_deep_extend("force", config, { root_dir = root }), { bufnr = buf })
end

return M
