if Config.only_essential_plugins() then return end

-- WARN: per-process `local installed` flag is wrong here — it resets every
-- nvim launch, re-running the slow build on every startup. Gate on the
-- actual binary's presence instead.
local function ensure_built()
  local ok, install = pcall(require, "dbee.install")
  if not ok then return end
  if vim.fn.executable(install.bin()) == 1 then return end
  local ok_dbee, dbee = pcall(require, "dbee")
  if not ok_dbee then return end
  pcall(dbee.install)
end

require("lazyload").on_vim_enter(function()
  -- WARN: nui must be added BEFORE nvim-dbee. dbee's plugin/dbee.lua does
  -- top-level `require("dbee")` which transitively pulls in `nui.tree` via
  -- dbee.ui.drawer at sourcing time. If nui isn't on rtp yet, require fails.
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
