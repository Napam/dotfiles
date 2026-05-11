-- vtsls: ts_ls successor. Inlay hints schema differs from ts_ls.

--- Resolve typescript-svelte-plugin from workspace node_modules. nil → not
--- installed → skip plugin (keeps non-Svelte projects clean).
--- WARN: tsserver resolves `location` from its own cwd, not workspace. Must be absolute.
--- WARN: check workspace's own node_modules first; monorepo parents may have an unrelated install.
---@param root string
---@return string?
local function find_svelte_plugin(root)
  if not root or root == "" then return nil end
  local own = vim.fs.joinpath(root, "node_modules", "typescript-svelte-plugin")
  if vim.uv.fs_stat(own) then return own end
  local nm = vim.fs.find("node_modules", { upward = true, type = "directory", path = root })[1]
  if not nm then return nil end
  local plugin = vim.fs.joinpath(nm, "typescript-svelte-plugin")
  if vim.uv.fs_stat(plugin) then return plugin end
  return nil
end

--- WARN: before_init runs once per client, not per buffer. Don't use
--- nvim_get_current_buf() — buffer may have switched before init RPC.
---@param params lsp.InitializeParams
---@return string?
local function root_from_params(params)
  if params.workspaceFolders and params.workspaceFolders[1] then
    return vim.uri_to_fname(params.workspaceFolders[1].uri)
  end
  if params.rootUri then
    return vim.uri_to_fname(params.rootUri)
  end
  return params.rootPath
end

---@type vim.lsp.Config
return {
  before_init = function(params, config)
    local plugin = find_svelte_plugin(root_from_params(params))
    if not plugin then return end
    config.settings = config.settings or {}
    config.settings.vtsls = vim.tbl_deep_extend("force", config.settings.vtsls or {}, {
      tsserver = {
        globalPlugins = {
          {
            name = "typescript-svelte-plugin",
            location = plugin,
            enableForWorkspaceTypeScriptVersions = true,
          },
        },
      },
    })
  end,
  settings = {
    typescript = {
      inlayHints = {
        enumMemberValues = { enabled = true },
        parameterNames = { enabled = "all" },
      },
    },
    javascript = {
      inlayHints = {
        enumMemberValues = { enabled = true },
        parameterNames = { enabled = "all" },
      },
    },
  },
}
