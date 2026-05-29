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

function M.profile_lock()
  return lock_path(Config.profile)
end

-- WARN: pause_count gates sync_back/sync_to from PackChanged and VimLeavePre.
-- Refcounted so nested pause_sync calls compose (inner resume_sync must not
-- re-enable sync mid-operation for an outer caller). Callers (e.g. pack_ui
-- restore) must ensure the runtime lockfile matches what they want propagated
-- BEFORE the final resume_sync(), otherwise the next PackChanged will clobber
-- the committed lockfile with stale runtime data.
local pause_count = 0

function M.pause_sync()
  pause_count = pause_count + 1
end

function M.resume_sync()
  if pause_count == 0 then
    vim.notify("packlock: resume_sync() called with no matching pause", vim.log.levels.ERROR)
    return
  end
  pause_count = pause_count - 1
end

local function sync_back()
  if pause_count > 0 then
    return
  end
  if vim.uv.fs_stat(runtime) then
    local ok, err = vim.uv.fs_copyfile(runtime, M.profile_lock())
    if not ok then
      vim.notify(
        "PackLockSync: failed to copy runtime to " .. M.profile_lock() .. ": " .. tostring(err),
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
  -- Plugins field is optional (a fresh/empty lockfile may omit it) but if
  -- present must be a table — sync_to and callers iterate it via pairs().
  if decoded.plugins ~= nil and type(decoded.plugins) ~= "table" then
    return nil, "invalid schema (plugins is not a table)"
  end
  return decoded
end

-- Pretty-print to match vim.pack's on-disk format (2-space indent, sorted keys)
-- so committed lockfile diffs stay minimal. Schema:
-- { "plugins": { <name>: { "rev": ..., "src": ..., ["version"]: ... } } }.
-- WARN: assumes a flat object-only schema. Non-empty arrays are delegated to
-- vim.json.encode (one-line, no recursion), so arrays-of-objects would not get
-- sorted keys; empty tables serialize as "{}" (object), not "[]". Fine for the
-- current schema (no arrays); revisit if vim.pack ever adds list-valued fields.
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
  local f, open_err = io.open(path, "w")
  if not f then
    return false, open_err or "io.open failed"
  end
  -- WARN: pcall the write so a disk-full / I/O error doesn't leak the handle.
  local ok, write_err = pcall(function()
    f:write(sorted_json_encode(tbl) .. "\n")
  end)
  f:close()
  if not ok then
    return false, tostring(write_err)
  end
  return true
end

--- Returns the profile in `profiles` that is not `p`. Assumes a two-profile
--- world (asserts otherwise); revisit if a third profile is added.
---@param p string
---@return string
local function other_profile(p)
  assert(#profiles == 2, "other_profile assumes exactly two profiles")
  return profiles[1] == p and profiles[2] or profiles[1]
end

--- Sync overlapping plugins from source → target. Target's package set is
--- preserved verbatim; only entries that also appear in source get their
--- fields (rev/src/version/...) overwritten from source. Target-only plugins
--- are untouched; source-only plugins are ignored.
---@param target "essentials"|"full"
local function sync_to(target)
  if pause_count > 0 then
    return
  end
  local source = other_profile(target)
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
  -- Safe: pairs allows replacing values for existing keys mid-iteration;
  -- only adding/removing keys is undefined.
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

  -- Skip the write when no overlapping rev differed; target file is
  -- unchanged. Avoids touching mtime and producing a no-op git diff if the
  -- pretty-printer's output ever drifts from the on-disk format.
  if updated > 0 then
    local ok, write_err = write_lock(tgt_path, tgt_lock)
    if not ok then
      vim.notify("PackLockSyncTo: failed to write " .. tgt_path .. ": " .. tostring(write_err), vim.log.levels.ERROR)
      return
    end
  end

  if target == Config.profile then
    local cp_ok, cp_err = vim.uv.fs_copyfile(tgt_path, runtime)
    if not cp_ok then
      vim.notify(
        "PackLockSyncTo: failed to copy " .. tgt_path .. " to " .. runtime .. ": " .. tostring(cp_err),
        vim.log.levels.ERROR
      )
    end
  end

  -- Skip the notification when no revs changed; PackChanged-driven syncs
  -- after every :Pack U would otherwise spam an info popup on every save.
  if updated > 0 then
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
end

--- Propagate the current profile's committed lockfile to the other profile.
--- Used by pack_ui restore: raw `git checkout` bypasses vim.pack, so no
--- PackChanged fires to trigger the normal cross-profile sync. Call after
--- resume_sync() (sync_to bails when pause_count > 0).
function M.sync_cross_profile()
  sync_to(other_profile(Config.profile))
end

function M.setup()
  assert(
    type(Config) == "table" and type(Config.profile) == "string",
    "packlock: Config.profile must be set before setup()"
  )
  assert(
    vim.tbl_contains(profiles, Config.profile),
    "packlock: invalid profile '" .. Config.profile .. "' (expected one of: " .. table.concat(profiles, ", ") .. ")"
  )
  -- WARN: always overwrite runtime from the committed profile lockfile at
  -- startup so a Config.profile switch between sessions picks up the new
  -- profile's revs. The previous session's VimLeavePre already flushed any
  -- unsaved runtime state into the committed lockfile, so the runtime file
  -- has no information not already on disk in the committed form.
  if vim.uv.fs_stat(M.profile_lock()) then
    local ok, err = vim.uv.fs_copyfile(M.profile_lock(), runtime)
    if not ok then
      vim.notify(
        "PackLockSync: failed to copy " .. M.profile_lock() .. " to " .. runtime .. ": " .. tostring(err),
        vim.log.levels.ERROR
      )
    end
  end

  vim.api.nvim_create_user_command("PackLockSyncTo", function(opts)
    local target = opts.fargs[1]
    if not vim.tbl_contains(profiles, target) then
      vim.notify("PackLockSyncTo: target must be one of: " .. table.concat(profiles, ", "), vim.log.levels.ERROR)
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
    sync_to(other_profile(Config.profile))
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

  -- WARN: augroup with clear=true makes setup() idempotent — a dev reload
  -- (re-source init.lua) otherwise stacks duplicate PackChanged/VimLeavePre
  -- handlers, firing full_sync N times per event.
  local group = vim.api.nvim_create_augroup("PackLockSync", { clear = true })

  vim.api.nvim_create_autocmd("PackChanged", { group = group, callback = debounced_sync })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      -- Flush any pending debounce synchronously before quit so a quit during
      -- the 200ms window can't leave the cross-profile lockfile stale.
      if sync_timer then
        vim.fn.timer_stop(sync_timer)
        sync_timer = nil
      end
      -- WARN: sync paused at exit => full_sync below bails silently; surface
      -- the situation so the user knows committed lockfile may be stale.
      if pause_count > 0 then
        vim.notify(
          "packlock: sync paused at exit (pause_count=" .. pause_count .. "); lockfile may be stale",
          vim.log.levels.WARN
        )
      end
      full_sync()
    end,
  })
end

return M
