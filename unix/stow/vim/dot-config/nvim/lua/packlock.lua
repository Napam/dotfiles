-- Per-profile vim.pack lockfile shim. vim.pack uses a single
-- nvim-pack-lock.json in stdpath('config'); we keep two committed lockfiles
-- (.full.json, .essentials.json) and route between them based on Config.profile.
--
-- Public entry point: M.setup() — call from init.lua BEFORE any vim.pack.add.

local M = {}

local cfg = vim.fn.stdpath("config")
local runtime = cfg .. "/nvim-pack-lock.json"

local profiles = { "essentials", "full" }

local function lock_path(p)
  return cfg .. "/nvim-pack-lock." .. p .. ".json"
end

local function profile_lock()
  return lock_path(Config.profile)
end

local function sync_back()
  if vim.uv.fs_stat(runtime) then
    local ok, err = vim.uv.fs_copyfile(runtime, profile_lock())
    if not ok then
      vim.notify(
        "PackLockSync: failed to copy runtime to " .. profile_lock() .. ": " .. tostring(err),
        vim.log.levels.ERROR
      )
    end
  end
end

function M.runtime_path()
  return runtime
end

function M.read_lock(path)
  local f = io.open(path, "r")
  if not f then
    return nil, "file not found"
  end
  local data = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, data, { luanil = { object = true, array = true } })
  if not ok then
    return nil, "invalid JSON: " .. tostring(decoded)
  end
  if type(decoded) ~= "table" then
    return nil, "invalid schema (not a table)"
  end
  return decoded
end

-- Pretty-print to match vim.pack's on-disk format (2-space indent, sorted keys)
-- so committed lockfile diffs stay minimal. Schema:
-- { "plugins": { <name>: { "rev": ..., "src": ..., ["version"]: ... } } }.
local function sorted_json_encode(tbl)
  local function encode(v, indent)
    if type(v) ~= "table" or (vim.islist(v) and #v > 0) then
      return vim.json.encode(v)
    end
    local keys = vim.tbl_keys(v)
    if #keys == 0 then
      return "{}"
    end
    table.sort(keys)
    local lines = {}
    local inner = indent .. "  "
    for _, k in ipairs(keys) do
      lines[#lines + 1] = inner .. vim.json.encode(k) .. ": " .. encode(v[k], inner)
    end
    return "{\n" .. table.concat(lines, ",\n") .. "\n" .. indent .. "}"
  end
  return '{\n  "plugins": ' .. encode(tbl.plugins or {}, "  ") .. "\n}"
end

local function write_lock(path, tbl)
  local f = io.open(path, "w")
  if not f then
    return false
  end
  f:write(sorted_json_encode(tbl) .. "\n")
  f:close()
  return true
end

--- Sync overlapping plugins from source → target. Target's package set is
--- preserved verbatim; only entries that also appear in source get their
--- fields (rev/src/version/...) overwritten from source. Target-only plugins
--- are untouched; source-only plugins are ignored.
---@param target "essentials"|"full"
local function sync_to(target)
  local source = (target == "essentials") and "full" or "essentials"
  local src_path, tgt_path = lock_path(source), lock_path(target)
  local src_lock, src_err = M.read_lock(src_path)
  local tgt_lock, tgt_err = M.read_lock(tgt_path)
  if not src_lock or not src_lock.plugins then
    vim.notify(
      "PackLockSyncTo: cannot read " .. src_path .. ": " .. (src_err or "missing plugins table"),
      vim.log.levels.ERROR
    )
    return
  end
  if not tgt_lock or not tgt_lock.plugins then
    vim.notify(
      "PackLockSyncTo: cannot read " .. tgt_path .. ": " .. (tgt_err or "missing plugins table"),
      vim.log.levels.ERROR
    )
    return
  end

  local updated, unchanged, target_only = 0, 0, 0
  for name, tgt_entry in pairs(tgt_lock.plugins) do
    local src_entry = src_lock.plugins[name]
    if src_entry then
      if tgt_entry.rev ~= src_entry.rev then
        updated = updated + 1
      else
        unchanged = unchanged + 1
      end
      local entry = {}
      for k, v in pairs(src_entry) do
        entry[k] = v
      end
      tgt_lock.plugins[name] = entry
    else
      target_only = target_only + 1
    end
  end

  if not write_lock(tgt_path, tgt_lock) then
    vim.notify("PackLockSyncTo: failed to write " .. tgt_path, vim.log.levels.ERROR)
    return
  end

  if target == Config.profile then
    local ok, err = vim.uv.fs_copyfile(tgt_path, runtime)
    if not ok then
      vim.notify(
        "PackLockSyncTo: failed to copy " .. tgt_path .. " to " .. runtime .. ": " .. tostring(err),
        vim.log.levels.ERROR
      )
    end
  end

  vim.notify(
    string.format(
      "PackLockSyncTo %s: %d rev(s) updated from %s, %d already matching, %d %s-only kept as-is",
      target,
      updated,
      source,
      unchanged,
      target_only,
      target
    ),
    vim.log.levels.INFO
  )
end

function M.setup()
  -- WARN: switching profiles mid-machine leaves stale runtime lock until :qa
  -- flushes both profiles via VimLeavePre full_sync.
  if vim.uv.fs_stat(profile_lock()) and not vim.uv.fs_stat(runtime) then
    local ok, err = vim.uv.fs_copyfile(profile_lock(), runtime)
    if not ok then
      vim.notify(
        "PackLockSync: failed to copy " .. profile_lock() .. " to " .. runtime .. ": " .. tostring(err),
        vim.log.levels.ERROR
      )
    end
  end

  vim.api.nvim_create_user_command("PackLockSyncTo", function(opts)
    local target = opts.fargs[1]
    if target ~= "essentials" and target ~= "full" then
      vim.notify("PackLockSyncTo: target must be 'essentials' or 'full'", vim.log.levels.ERROR)
      return
    end
    sync_to(target)
  end, {
    nargs = 1,
    complete = function(arg_lead)
      return vim.tbl_filter(function(p)
        return vim.startswith(p, arg_lead)
      end, profiles)
    end,
  })

  -- WARN: vim.pack.update fires PackChanged per plugin. Debounce so we sync
  -- lockfiles once per batch instead of N times. Use vim.fn.timer_start (number
  -- IDs) — vim.defer_fn returns a uv_timer_t userdata which timer_stop rejects.
  -- Callback runs on the main event loop, so vim.uv.fs_* sync + vim.notify are safe.
  local function full_sync()
    sync_back()
    sync_to((Config.profile == "essentials") and "full" or "essentials")
  end
  local sync_timer = nil
  local function flush_sync()
    sync_timer = nil
    full_sync()
  end
  local function debounced_sync()
    if sync_timer then
      vim.fn.timer_stop(sync_timer)
    end
    sync_timer = vim.fn.timer_start(200, flush_sync)
  end

  vim.api.nvim_create_autocmd("PackChanged", { callback = debounced_sync })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      -- Flush any pending debounce synchronously before quit so a quit during
      -- the 200ms window can't leave the cross-profile lockfile stale.
      if sync_timer then
        vim.fn.timer_stop(sync_timer)
        sync_timer = nil
      end
      full_sync()
    end,
  })
end

return M
