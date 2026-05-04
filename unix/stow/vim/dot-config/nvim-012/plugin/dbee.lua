if Config.only_essential_plugins() then return end

-- dbee.install builds a Go binary at `vim.fn.stdpath("data").."/dbee/bin/dbee"`.
-- A per-process `local installed` flag is wrong here — it resets every nvim
-- launch, re-running the (slow, network-touching) build on every startup.
-- Gate on the actual binary's presence instead so the build only runs once.
local function ensure_built()
  local ok, install = pcall(require, "dbee.install")
  if not ok then return end
  if vim.fn.executable(install.bin()) == 1 then return end
  local ok_dbee, dbee = pcall(require, "dbee")
  if not ok_dbee then return end
  pcall(dbee.install)
end

require("lazyload").on_vim_enter(function()
  -- nui must be added BEFORE nvim-dbee: dbee's plugin/dbee.lua does
  -- top-level `require("dbee")`, which transitively pulls in `nui.tree` via
  -- dbee.ui.drawer at plugin-sourcing time. If nui isn't on runtimepath yet,
  -- the require fails with "module 'nui.tree' not found".
  vim.pack.add({
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/kndndrj/nvim-dbee" },
  })

  ensure_built()

  local sources = {}
  local dbee_json = vim.fs.find("dbee.json", { upward = true })[1]
  if dbee_json then
    table.insert(sources, require("dbee.sources").FileSource:new(dbee_json))
  end

  require("dbee").setup({ sources = sources })
end)
