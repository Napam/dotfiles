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

---@param path string
---@return boolean
local function depends_on_tailwind(path)
  local data = read(path)
  return data ~= nil and data:find('"tailwindcss"', 1, true) ~= nil
end

---@param root string
---@return boolean
local function has_tailwind(root)
  for _, name in ipairs({
    "tailwind.config.js",
    "tailwind.config.cjs",
    "tailwind.config.mjs",
    "tailwind.config.ts",
  }) do
    if vim.fn.filereadable(root .. "/" .. name) == 1 then
      return true
    end
  end

  if depends_on_tailwind(root .. "/package.json") then
    return true
  end

  -- Monorepos keep the package.json in the app directory (web/ in
  -- backwerust-template, apps/web in others). One level is enough for both.
  for name, kind in vim.fs.dir(root) do
    if kind == "directory" and name ~= "node_modules" and name ~= "target" then
      if depends_on_tailwind(root .. "/" .. name .. "/package.json") then
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

  local root = vim.fs.root(buf, { ".git" }) or vim.fs.root(buf, { "Cargo.toml" })
  if not root or not has_tailwind(root) then
    return
  end

  if #vim.lsp.get_clients({ bufnr = buf, name = "tailwindcss" }) > 0 then
    return
  end

  local config = vim.lsp.config["tailwindcss"]
  if not config then
    return
  end

  vim.lsp.start(vim.tbl_deep_extend("force", config, { root_dir = root }), { bufnr = buf })
end

return M
