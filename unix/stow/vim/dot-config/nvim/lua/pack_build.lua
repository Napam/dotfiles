-- Shared helper for plugins with a build/install step.
-- Usage: require("pack_build").run_install_sh(name, plugin_dir, opts?)
--   name: display name for notifications
--   plugin_dir: directory containing install.sh
--   opts.reason: string appended to the "running" notify message
--   opts.check_binary: optional glob (relative to plugin_dir) verified after install
-- WARN: install.sh is always invoked as `sh install.sh`. Fresh git clones
-- commonly lack +x on install.sh, and `sh` invocation always works on POSIX.
local M = {}

-- WARN: in-flight set keyed by installer path. Prevents concurrent install.sh
-- runs (PackChanged + ensure_built can otherwise race on first bootstrap).
local inflight = {}

local function join_path(parent, child)
  if child and child ~= "" then
    return parent .. "/" .. child
  end
  return parent
end

function M.run_install_sh(name, plugin_dir, opts)
  opts = opts or {}
  local installer = plugin_dir .. "/install.sh"
  if vim.fn.filereadable(installer) ~= 1 then
    vim.notify(name .. ": install.sh not found at " .. installer, vim.log.levels.WARN)
    return
  end
  if inflight[installer] then
    vim.notify(name .. ": install already in progress", vim.log.levels.INFO)
    return
  end
  inflight[installer] = true
  local suffix = opts.reason and (" (" .. opts.reason .. ")") or ""
  vim.notify(name .. ": running install.sh" .. suffix .. " ...", vim.log.levels.INFO)
  vim.system({ "sh", installer }, { cwd = plugin_dir }, function(out)
    vim.schedule(function()
      inflight[installer] = nil
      if out.code ~= 0 then
        local detail
        if out.stderr and #out.stderr > 0 then
          detail = out.stderr
        elseif out.stdout and #out.stdout > 0 then
          detail = out.stdout
        else
          detail = "exit " .. out.code
        end
        vim.notify(name .. ": install.sh failed: " .. detail, vim.log.levels.ERROR)
      elseif opts.check_binary and #vim.fn.glob(join_path(plugin_dir, opts.check_binary), false, true) == 0 then
        vim.notify(name .. ": install.sh succeeded but no artifact found (unsupported platform?)", vim.log.levels.ERROR)
      else
        vim.notify(name .. ": build complete", vim.log.levels.INFO)
      end
    end)
  end)
end

--- Register a PackChanged autocmd filtered to one pack name.
--- WARN: must be called at top-level (not inside on_vim_enter) so it fires
--- on first bootstrap regardless of when vim.pack.add runs.
function M.on_pack_changed(pack_name, fn)
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      if ev.data.spec.name ~= pack_name then
        return
      end
      -- WARN: PackChanged fires on install/update/delete. Build hooks must
      -- skip delete or they re-run install.sh against a vanishing dir.
      if ev.data.kind == "delete" then
        return
      end
      fn(ev)
    end,
  })
end

--- Register a build-step plugin: wires PackChanged autocmd for install/update.
--- Caller still invokes ensure_built() inside on_vim_enter as the post-add
--- safety net (PackChanged doesn't fire on later startups with a missing artifact).
--- WARN: must be called at top-level so PackChanged fires on first bootstrap.
---@param pack_name string
---@param subdir string|nil  subdirectory of plugin containing install.sh
---@param opts { check_binary?: string, reason?: string }  check_binary should generally be provided
function M.register(pack_name, subdir, opts)
  opts = opts or {}
  M.on_pack_changed(pack_name, function(ev)
    -- WARN: "keep" → first table wins per key. opts first so caller's
    -- reason (if any) overrides the "PackChanged" default.
    M.run_install_sh(
      pack_name,
      join_path(ev.data.path, subdir),
      vim.tbl_extend("keep", opts, { reason = "PackChanged" })
    )
  end)
end

--- Safety net for plugins loaded after first install: PackChanged only fires
--- on install/update, so a missing artifact on later startups goes unrepaired.
---@param pack_name string
---@param subdir string|nil  subdirectory of plugin containing install.sh
---@param opts { check_binary?: string, reason?: string }
---@return "ok"|"rebuilding"|"no_plugin"
function M.ensure_built(pack_name, subdir, opts)
  opts = opts or {}
  local entry = vim.pack.get({ pack_name })[1]
  if not entry then
    return "no_plugin"
  end
  local dir = join_path(entry.path, subdir)
  if opts.check_binary then
    if #vim.fn.glob(join_path(dir, opts.check_binary), false, true) > 0 then
      return "ok"
    end
  else
    -- WARN: no check_binary → can't verify; assume rebuild needed.
    M.run_install_sh(pack_name, dir, opts)
    return "rebuilding"
  end
  M.run_install_sh(pack_name, dir, opts)
  return "rebuilding"
end

--- One-stop setup for a build-step plugin. Call at top-level.
--- Returns a function to invoke inside on_vim_enter after vim.pack.add.
---@param pack_name string
---@param subdir string|nil
---@param opts { check_binary?: string }
function M.setup(pack_name, subdir, opts)
  opts = opts or {}
  M.register(pack_name, subdir, opts)
  return function()
    M.ensure_built(pack_name, subdir, vim.tbl_extend("keep", opts, { reason = "missing binary" }))
  end
end

return M
