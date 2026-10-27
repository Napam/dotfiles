-- Per-profile vim.pack lockfile shim. vim.pack uses a single
-- nvim-pack-lock.json in stdpath('config'); we keep two committed lockfiles
-- (.full.json, .essentials.json) and route between them based on Config.profile.
--
-- Public entry point: M.setup() — call from init.lua BEFORE any vim.pack.add.

local M = {}

local cfg = vim.fn.stdpath("config")
local runtime = cfg .. "/nvim-pack-lock.json"

local profiles = { "essentials", "full" }

-- Forward declaration: sync_back runs before write_lock in file order.
local write_lock

-- WARN: vim.pack adopts every plugin directory it finds, including ones
-- installed for the other profile. allowed_plugins keeps sync_back from
-- writing those extras into the active profile's committed lock.
local allowed_plugins = {}
local sync_disabled = false
local pack_used = false
local wrapped = false

-- WARN: pack_ui restore moves HEADs with raw `git checkout`, but vim.pack keeps
-- the old revs in memory and writes them back on its next lock write. No public
-- API reloads that lock, so pinned revs override runtime entries until vim.pack
-- itself changes the plugin (PackChanged) or nvim restarts.
local rev_pins = {}

-- WARN: lazy vim.pack.add calls run after VimEnter (lazyload queues). An
-- earlier check would flag those plugins as stale. Adds gated on a callback
-- that may never fire (parser install) should register with load=false first.
local STALE_CHECK_DELAY_MS = 10000

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

--- Names registered with vim.pack.add() this session, including load=false
--- restore calls. Skips vim.pack.get() when no add ran: that avoids lock_read()
--- installing the lock on a config that failed before the first add.
---@return table<string, true>
local function active_names()
  local active = {}
  if pack_used then
    for _, p in ipairs(vim.pack.get(nil, { info = false })) do
      if p.active then
        active[p.spec.name] = true
      end
    end
  end
  return active
end

local function read_runtime()
  local lock, err = M.read_lock(runtime)
  if lock and lock.plugins then
    for name, rev in pairs(rev_pins) do
      if lock.plugins[name] then
        lock.plugins[name].rev = rev
      end
    end
  end
  return lock, err
end

local function sync_back()
  if pause_count > 0 or sync_disabled then
    return
  end
  if not vim.uv.fs_stat(runtime) then
    return
  end
  local lock, err = read_runtime()
  if not lock then
    vim.notify("PackLockSync: cannot read " .. runtime .. ": " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  local active = active_names()
  local plugins = {}
  for name, entry in pairs(lock.plugins or {}) do
    if allowed_plugins[name] or active[name] then
      plugins[name] = entry
    end
  end
  local ok, write_err = write_lock(M.profile_lock(), { plugins = plugins })
  if not ok then
    vim.notify(
      "PackLockSync: failed to write " .. M.profile_lock() .. ": " .. tostring(write_err),
      vim.log.levels.ERROR
    )
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

-- WARN: write a sibling temp file, fsync, then rename over the target so a
-- crash mid-write leaves the old lock intact. Temp must share the target's
-- directory: rename is only atomic within one filesystem. Renaming onto a
-- symlink would replace the link (per-file stow), so write next to its target.
write_lock = function(path, tbl)
  local link = vim.uv.fs_lstat(path)
  if link and link.type == "link" then
    local real, real_err = vim.uv.fs_realpath(path)
    if not real then
      return false, "cannot resolve symlink: " .. tostring(real_err)
    end
    path = real
  end
  local st = vim.uv.fs_stat(path)
  local mode = st and bit.band(st.mode, tonumber("777", 8)) or tonumber("644", 8)

  -- Unique per process; "wx" so a leftover temp from a crashed process is
  -- never written through or unlinked by someone else.
  local data = sorted_json_encode(tbl) .. "\n"
  local tmp, fd, open_err
  for i = 0, 9 do
    tmp = string.format("%s.%d.%d.tmp", path, vim.uv.os_getpid(), i)
    fd, open_err = vim.uv.fs_open(tmp, "wx", mode)
    if fd or not tostring(open_err):match("^EEXIST") then
      break
    end
  end
  if not fd then
    return false, open_err or "fs_open failed"
  end
  local err = nil
  local chmoded, chmod_err = vim.uv.fs_fchmod(fd, mode)
  if not chmoded then
    err = chmod_err or "fs_fchmod failed"
  end
  if not err then
    local written, write_err = vim.uv.fs_write(fd, data)
    if not written then
      err = write_err or "fs_write failed"
    elseif written ~= #data then
      err = "short write"
    else
      local synced, sync_err = vim.uv.fs_fsync(fd)
      if not synced then
        err = sync_err or "fs_fsync failed"
      end
    end
  end
  vim.uv.fs_close(fd)
  if not err then
    local renamed, rename_err = vim.uv.fs_rename(tmp, path)
    if renamed then
      return true
    end
    err = rename_err or "fs_rename failed"
  end
  vim.uv.fs_unlink(tmp)
  return false, err
end

--- Build the runtime lock: active profile entries plus valid entries for
--- already-installed plugins from the other profile or the previous runtime
--- lock. Without this vim.pack treats every extra directory as corrupt and
--- repairs it on each essentials startup (two git calls per plugin).
---@param active table|nil decoded profile lock
---@param other table|nil decoded other-profile lock
---@param existing table|nil decoded previous runtime lock
---@return table
local function runtime_lock(active, other, existing)
  local plug_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
  local plugins = {}

  local function put(name, entry)
    if plugins[name] == nil then
      plugins[name] = entry
    end
  end

  for name, entry in pairs((active and active.plugins) or {}) do
    put(name, entry)
  end
  -- Committed locks win over the previous runtime lock so a `git checkout` of
  -- either lock takes effect. Cost: an update not yet synced back when nvim
  -- crashed is dropped, same as for active-profile plugins.
  for _, lock in ipairs({ other, existing }) do
    for name, entry in pairs((lock and lock.plugins) or {}) do
      if plugins[name] == nil then
        local ok_entry = type(entry) == "table" and type(entry.rev) == "string" and type(entry.src) == "string"
        if ok_entry and vim.uv.fs_stat(vim.fs.joinpath(plug_dir, name)) then
          put(name, entry)
        end
      end
    end
  end
  return { plugins = plugins }
end

--- Returns the profile in `profiles` that is not `p`. Assumes a two-profile
--- world (asserts otherwise); revisit if a third profile is added.
---@param p string
---@return string
local function other_profile(p)
  assert(#profiles == 2, "other_profile assumes exactly two profiles")
  return profiles[1] == p and profiles[2] or profiles[1]
end

--- Sync overlapping plugins from source → target. Automatic syncs pass the
--- runtime lock: it reflects what is on disk (active profile plus installed
--- extras), so a full-only plugin updated during an essentials session still
--- reaches the full lock. `:PackLockSyncTo` passes the other profile's
--- committed lock. Target's package set is preserved verbatim; only entries
--- that also appear in source get their fields (rev/src/version/...)
--- overwritten. Target-only plugins are untouched; source-only ignored.
---@param target "essentials"|"full"
---@param source_path string
local function sync_to(target, source_path)
  if pause_count > 0 or sync_disabled then
    return
  end
  local tgt_path = lock_path(target)
  local src_lock, src_err
  if source_path == runtime then
    src_lock, src_err = read_runtime()
  else
    src_lock, src_err = M.read_lock(source_path)
  end
  local tgt_lock, tgt_err = M.read_lock(tgt_path)
  if not src_lock or not src_lock.plugins then
    vim.notify(
      "PackLockSyncTo: cannot read " .. source_path .. ": " .. (src_err or "missing plugins table"),
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
      if vim.deep_equal(tgt_entry, src_entry) then
        unchanged = unchanged + 1
      else
        updated = updated + 1
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

  -- Skip the write when no overlapping entry differed; target file is
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
    -- Keep installed extras in the runtime lock; a plain copy would drop them.
    local other = M.read_lock(lock_path(other_profile(target)))
    local existing = M.read_lock(runtime)
    local ok, write_err = write_lock(runtime, runtime_lock(tgt_lock, other, existing))
    if not ok then
      vim.notify("PackLockSyncTo: failed to write " .. runtime .. ": " .. tostring(write_err), vim.log.levels.ERROR)
    end
  end

  -- Skip the notification when no entries changed; PackChanged-driven syncs
  -- after every :Pack U would otherwise spam an info popup on every save.
  if updated > 0 then
    local source_label = source_path == runtime and "runtime" or "committed lock"
    vim.notify(
      string.format(
        "PackLockSyncTo %s: %d entr(ies) updated from %s, %d already matching, %d %s-only kept as-is",
        target,
        updated,
        source_label,
        unchanged,
        target_only,
        target
      ),
      vim.log.levels.INFO
    )
  end
end

--- Propagate the runtime lockfile to the other profile. Used by pack_ui
--- restore: raw `git checkout` bypasses vim.pack, so no PackChanged fires to
--- trigger the normal cross-profile sync. Call after resume_sync() (sync_to
--- bails when pause_count > 0).
function M.sync_cross_profile()
  sync_to(other_profile(Config.profile), runtime)
end

---@return string
function M.other_profile()
  return other_profile(Config.profile)
end

---@return string
function M.other_profile_lock()
  return lock_path(other_profile(Config.profile))
end

--- Override vim.pack's stale in-memory revs after a raw `git checkout`.
---@param revs table<string, string> plugin name -> restored rev
function M.pin_revs(revs)
  for name, rev in pairs(revs) do
    rev_pins[name] = rev
  end
end

---@param name string
---@return string|nil
function M.pinned_rev(name)
  return rev_pins[name]
end

--- Names in the committed profile lock that no vim.pack.add() registered this
--- session. They still install on a fresh machine for this profile.
---@return string[]
function M.unregistered_plugins()
  if sync_disabled or not pack_used then
    return {}
  end
  local lock = M.read_lock(M.profile_lock())
  if not lock then
    return {}
  end
  local active = active_names()
  local names = {}
  for name in pairs(lock.plugins or {}) do
    if not active[name] then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
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
  sync_disabled = false
  allowed_plugins = {}
  -- Seed the write filter from the committed profile lock. A lock that exists
  -- but cannot be read disables sync instead of falling back to a verbatim
  -- runtime copy, which is how the essentials lock got polluted.
  local lock_exists = vim.uv.fs_lstat(M.profile_lock()) ~= nil
  local committed, committed_err = M.read_lock(M.profile_lock())
  if committed then
    for name in pairs(committed.plugins or {}) do
      allowed_plugins[name] = true
    end
  elseif not lock_exists then
    allowed_plugins = {}
  else
    sync_disabled = true
    vim.notify(
      "packlock: cannot read " .. M.profile_lock() .. ": " .. tostring(committed_err) .. "; lock sync disabled",
      vim.log.levels.ERROR
    )
  end

  -- WARN: track that a pack call happened so VimLeavePre does not make
  -- vim.pack.get() read/install the lock on a config that failed before the
  -- first vim.pack.add.
  if not wrapped then
    wrapped = true
    local pack_add = vim.pack.add
    vim.pack.add = function(specs, opts)
      pack_used = true
      return pack_add(specs, opts)
    end
  end

  -- Rebuild runtime from the committed profile lock, plus valid entries for
  -- installed plugins owned by the other profile. WARN: a plain copy made
  -- vim.pack treat those extras as corrupt and repair them every startup.
  local other = M.read_lock(lock_path(other_profile(Config.profile)))
  local existing = M.read_lock(runtime)
  local ok, err = write_lock(runtime, runtime_lock(committed, other, existing))
  if not ok then
    vim.notify("PackLockSync: failed to write " .. runtime .. ": " .. tostring(err), vim.log.levels.ERROR)
  end

  vim.api.nvim_create_user_command("PackLockSyncTo", function(opts)
    local target = opts.fargs[1]
    if not vim.tbl_contains(profiles, target) then
      vim.notify("PackLockSyncTo: target must be one of: " .. table.concat(profiles, ", "), vim.log.levels.ERROR)
      return
    end
    if sync_disabled then
      vim.notify("PackLockSyncTo: lock sync disabled after a read error", vim.log.levels.ERROR)
      return
    end
    sync_to(target, lock_path(other_profile(target)))
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
    sync_to(other_profile(Config.profile), runtime)
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

  vim.api.nvim_create_autocmd("PackChanged", {
    group = group,
    callback = function(ev)
      -- vim.pack now holds the real rev for this plugin.
      rev_pins[ev.data.spec.name] = nil
      debounced_sync()
    end,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function()
      vim.fn.timer_start(STALE_CHECK_DELAY_MS, function()
        local names = M.unregistered_plugins()
        if #names > 0 then
          vim.notify(
            string.format(
              "packlock: %d plugin(s) in the %s lock were not added this session but still install on fresh machines: %s. If no config adds them, drop them from the lock.",
              #names,
              Config.profile,
              table.concat(names, ", ")
            ),
            vim.log.levels.WARN
          )
        end
      end)
    end,
  })
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
