-- Minimal vim.pack UI. :Pack opens a floating dashboard (update/clean/log/inspect).
-- Based on Andreas Schneider's pack-ui:
-- https://git.cryptomilk.org/users/asn/dotfiles.git/tree/dot_config/nvim/lua/plugins/pack-ui.lua

require("lazyload").on_vim_enter(function()
  local api = vim.api
  local ns = api.nvim_create_namespace("pack_ui")

  local MAX_COMMITS_PREVIEW = 10

  local function setup_highlights()
    local links = {
      PackUiHeader = "Title",
      PackUiButton = "Function",
      PackUiPluginLoaded = "String",
      PackUiPluginNotLoaded = "Comment",
      PackUiPluginMissing = "ErrorMsg",
      PackUiUpdateAvailable = "DiagnosticInfo",
      PackUiBreaking = "DiagnosticWarn",
      PackUiVersion = "Number",
      PackUiSectionHeader = "Label",
      PackUiSeparator = "FloatBorder",
      PackUiDetail = "Comment",
      PackUiHelp = "SpecialComment",
    }
    for group, target in pairs(links) do
      api.nvim_set_hl(0, group, { link = target, default = true })
    end
  end

  local state = {
    bufnr = nil,
    winid = nil,
    win_autocmd_id = nil,
    line_to_plugin = {}, -- 1-based line => plugin name
    plugin_lines = {}, -- plugin name => 1-based line
    expanded = {},
    show_help = false,
    updates = {}, -- plugin => list of new commit lines
    breaking = {}, -- plugin => bool (major bump or breaking commit)
    unreleased = {}, -- plugin => unreleased commit lines
    unreleased_breaking = {}, -- plugin => unreleased breaking commit lines
    show_all_commits = {},
    latest_ref = {}, -- plugin => latest version/hash
    checking = false,
    restoring = false,
    -- Cancellation token. Captured at callback creation; compared on
    -- callback completion — mismatch = stale callback, drop the result.
    -- Bumped on every check/restore start and by reset_state() (which
    -- close() calls). Never bumped directly by close().
    check_id = 0,
  }

  local function clear_check_state()
    state.updates = {}
    state.breaking = {}
    state.unreleased = {}
    state.unreleased_breaking = {}
    state.latest_ref = {}
    state.show_all_commits = {}
  end

  -- path => installed semver tag (false = none found). Session-cached.
  local tag_cache = {}
  -- path => resolved remote default branch (false = failed). Session-cached;
  -- the default branch never changes mid-session.
  local ref_cache = {}

  local function get_version_str(p)
    local v = p.spec.version
    if v == nil then
      return ""
    end
    if type(v) == "string" then
      return v
    end
    return tostring(v)
  end

  local function has_semver_version(version)
    if version == "" then
      return false
    end
    return version == "*" or version:match("%d") ~= nil
  end

  -- Parse semver from a tag, returns {major, minor, patch} or nil
  local function parse_semver(tag)
    if not tag then
      return nil
    end
    local major, minor, patch = tag:match("^v?(%d+)%.(%d+)%.(%d+)")
    if major then
      return { tonumber(major), tonumber(minor), tonumber(patch) }
    end
    return nil
  end

  local function semver_gt(a, b)
    if not a or not b then
      return false
    end
    if a[1] ~= b[1] then
      return a[1] > b[1]
    end
    if a[2] ~= b[2] then
      return a[2] > b[2]
    end
    return a[3] > b[3]
  end

  -- Returns the installed semver tag (cached for the session).
  local function get_installed_tag(path)
    if not path then
      return nil
    end
    if tag_cache[path] ~= nil then
      return tag_cache[path] or nil
    end

    local result = vim.system({ "git", "-C", path, "tag", "--points-at", "HEAD" }, { text = true }):wait()
    if result.code == 0 then
      local latest_tag = nil
      local latest_ver = nil
      for tag in result.stdout:gmatch("[^\n]+") do
        local version = parse_semver(tag)
        if version and (not latest_ver or semver_gt(version, latest_ver)) then
          latest_tag = tag
          latest_ver = version
        end
      end
      if latest_tag then
        tag_cache[path] = latest_tag
        return latest_tag
      end
    end

    tag_cache[path] = false
    return nil
  end

  -- Parse `git log --oneline` stdout into a list of strings
  local function parse_commits(stdout)
    local commits = {}
    if stdout and stdout ~= "" then
      for line in stdout:gmatch("[^\n]+") do
        table.insert(commits, line)
      end
    end
    return commits
  end

  -- Async `git log --oneline <range>`; calls callback(commits).
  local function git_log(path, range, callback)
    vim.system({ "git", "-C", path, "log", "--oneline", range }, { text = true }, function(res)
      callback(parse_commits(res.code == 0 and res.stdout or ""))
    end)
  end

  -- Conventional commit breaking marker: 'type!:' or 'type(scope)!:'
  -- WARN: only detects subject-line markers. `BREAKING CHANGE:` /
  -- `BREAKING-CHANGE:` footers in the commit body are missed because all
  -- callers feed `git log --oneline` output (subjects only). Accepted
  -- false-negative; switching to `--format=%B` would require multi-line
  -- parsing across every git_log call.
  local function is_breaking_commit(c)
    return c:match("%x+ %w+!:") or c:match("%x+ %w+%b()!:")
  end

  local function has_breaking_commit(commits)
    return vim.iter(commits):any(is_breaking_commit)
  end

  local function filter_breaking(commits)
    return vim.iter(commits):filter(is_breaking_commit):totable()
  end

  -- Forward decl: check_updates calls render() before render is defined.
  local render

  -- Resolve the remote default branch ref (cached per session).
  local function resolve_remote_ref(path, callback)
    if ref_cache[path] ~= nil then
      callback(ref_cache[path] or nil)
      return
    end
    vim.system({ "git", "-C", path, "symbolic-ref", "refs/remotes/origin/HEAD" }, { text = true }, function(result)
      if result.code == 0 then
        local ref = vim.trim(result.stdout)
        ref_cache[path] = ref
        callback(ref)
        return
      end
      vim.system({ "git", "-C", path, "rev-parse", "--verify", "origin/main" }, { text = true }, function(r)
        if r.code == 0 then
          ref_cache[path] = "origin/main"
          callback("origin/main")
        else
          vim.system({ "git", "-C", path, "rev-parse", "--verify", "origin/master" }, { text = true }, function(r2)
            if r2.code == 0 then
              ref_cache[path] = "origin/master"
              callback("origin/master")
            else
              ref_cache[path] = false
              callback(nil)
            end
          end)
        end
      end)
    end)
  end

  -- Fetch all plugins and check for new commits on the remote
  local function check_updates()
    if state.checking or state.restoring then
      return
    end

    local plugins = vim.pack.get(nil, { info = false })
    if #plugins == 0 then
      return
    end

    state.check_id = state.check_id + 1
    local my_check_id = state.check_id
    state.checking = true
    clear_check_state()
    render()

    local remaining = #plugins

    local function finish_one(result)
      vim.schedule(function()
        remaining = remaining - 1
        if state.check_id ~= my_check_id then
          return
        end
        if result then
          if result.updates ~= nil then
            state.updates[result.name] = result.updates
          end
          if result.breaking then
            state.breaking[result.name] = true
          end
          if result.unreleased then
            state.unreleased[result.name] = result.unreleased
          end
          if result.unreleased_breaking then
            state.unreleased_breaking[result.name] = result.unreleased_breaking
          end
          if result.latest_ref then
            state.latest_ref[result.name] = result.latest_ref
          end
        end
        if remaining == 0 then
          state.checking = false
          for name, commits in pairs(state.updates) do
            if #commits > 0 then
              state.expanded[name] = true
            end
          end
          render()
        end
      end)
    end

    -- `git log <range>` + breaking detection. `latest_ref_from_commit`:
    -- when true, derive latest_ref from the newest commit's short hash
    -- (non-versioned plugins); when false, caller sets it from the tag.
    local function log_against(path, range, latest_ref_from_commit, cb)
      git_log(path, range, function(commits)
        local out = { commits = commits, breaking = has_breaking_commit(commits) }
        if latest_ref_from_commit and #commits > 0 then
          out.latest_ref = commits[1]:match("^(%x+)")
        end
        cb(out)
      end)
    end

    for _, p in ipairs(plugins) do
      local path = p.path
      local name = p.spec.name
      local version = get_version_str(p)
      local has_semver = has_semver_version(version)
      local current_tag = has_semver and get_installed_tag(path) or nil

      -- Only fetch tags for versioned plugins; non-versioned ones compare
      -- against the default branch and don't need tag refs.
      local fetch_args = { "git", "-C", path, "fetch", "--quiet" }
      if has_semver then
        table.insert(fetch_args, "--tags")
      end
      -- WARN: 30s timeout — without it a slow/unreachable remote hangs the
      -- fetch indefinitely, leaving state.checking == true forever and
      -- blocking restore + future :Pack C invocations for the session.
      -- Timeout surfaces as a non-zero result.code, routed to the error path.
      vim.system(fetch_args, { timeout = 30000 }, function(fetch_res)
        if fetch_res.code ~= 0 then
          finish_one(nil)
          return
        end

        if has_semver then
          -- Versioned plugin: compare against latest tag, then check main for unreleased commits.
          vim.system(
            { "git", "-C", path, "tag", "--list", "--sort=-version:refname" },
            { text = true },
            function(tag_res)
              local cur_ver = parse_semver(current_tag)
              local latest_tag = nil
              local latest_ver = nil
              if tag_res.code == 0 then
                for t in tag_res.stdout:gmatch("[^\n]+") do
                  local v = parse_semver(t)
                  if v and (not latest_ver or semver_gt(v, latest_ver)) then
                    latest_tag = t
                    latest_ver = v
                  end
                end
              end

              local result = { name = name }

              if cur_ver and latest_ver and latest_ver[1] > cur_ver[1] then
                result.breaking = true
              end

              -- After released commits: check main for unreleased commits past latest tag.
              -- Skip when no tags exist (nothing is "released" yet, so unreleased-commits label would be misleading).
              local function after_released()
                if not latest_tag then
                  finish_one(result)
                  return
                end
                resolve_remote_ref(path, function(ref)
                  if not ref then
                    finish_one(result)
                    return
                  end
                  git_log(path, latest_tag .. ".." .. ref, function(unreleased)
                    if #unreleased > 0 then
                      result.unreleased = unreleased
                    end
                    local breaking_lines = filter_breaking(unreleased)
                    if #breaking_lines > 0 then
                      result.unreleased_breaking = breaking_lines
                    end
                    finish_one(result)
                  end)
                end)
              end

              local is_newer = (cur_ver and latest_ver and semver_gt(latest_ver, cur_ver))
                or (not cur_ver and latest_tag ~= nil)
              if is_newer and latest_tag then
                log_against(path, "HEAD.." .. latest_tag, false, function(r)
                  result.updates = r.commits
                  if #r.commits > 0 then
                    result.latest_ref = latest_tag
                  end
                  if r.breaking then
                    result.breaking = true
                  end
                  after_released()
                end)
              else
                result.updates = {}
                after_released()
              end
            end
          )
        else
          -- Non-versioned plugin: compare against default branch
          resolve_remote_ref(path, function(ref)
            if not ref then
              finish_one(nil)
              return
            end
            log_against(path, "HEAD.." .. ref, true, function(r)
              local result = { name = name, updates = r.commits, latest_ref = r.latest_ref }
              if r.breaking then
                result.breaking = true
              end
              finish_one(result)
            end)
          end)
        end
      end)
    end
  end

  -- Restore all plugins to revisions in the runtime lockfile.
  -- For each entry: install if missing, then `git checkout <rev>` (detached).
  -- Async via vim.system; reports a summary when all plugins finish.
  -- WARN: does not coordinate with an open vim.pack.update() confirm tab —
  -- if one is open, restoring concurrently can race on the lockfile write.
  local function restore_from_lock()
    if state.checking or state.restoring then
      vim.notify("vim.pack: busy, try again", vim.log.levels.WARN)
      return
    end

    local packlock = require("packlock")
    local lock_path = packlock.profile_lock()
    local lock, err = packlock.read_lock(lock_path)
    if not lock then
      vim.notify("vim.pack: lockfile read failed (" .. lock_path .. "): " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    if type(lock.plugins) ~= "table" then
      vim.notify("vim.pack: invalid lockfile (missing plugins table)", vim.log.levels.ERROR)
      return
    end

    local entries = {}
    for name, entry in pairs(lock.plugins) do
      if type(entry) == "table" and entry.rev then
        table.insert(entries, { name = name, rev = entry.rev, src = entry.src, version = entry.version })
      end
    end
    if #entries == 0 then
      vim.notify("vim.pack: lockfile has no plugins", vim.log.levels.INFO)
      return
    end

    local msg = string.format("Restore %d plugin(s) to lockfile revisions?", #entries)
    if vim.fn.confirm(msg, "&Yes\n&No", 2, "Question") ~= 1 then
      return
    end

    local installed = {}
    for _, p in ipairs(vim.pack.get(nil, { info = false })) do
      installed[p.spec.name] = p.path
    end

    state.restoring = true
    state.check_id = state.check_id + 1
    local my_check_id = state.check_id
    -- Clear stale per-plugin update state up-front so the UI doesn't show
    -- "↑N" arrows from a prior check while restore is in progress.
    clear_check_state()
    render()

    -- WARN: must pause BEFORE the first vim.pack.add (missing-plugin path) so
    -- the resulting PackChanged doesn't fire sync_back and clobber the
    -- committed lockfile with the still-stale runtime file.
    packlock.pause_sync()

    local remaining = #entries
    local restored, skipped, errors = 0, 0, 0

    -- WARN: copy the committed lockfile verbatim to runtime rather than
    -- rebuilding from vim.pack.get(), so the runtime is byte-for-byte
    -- identical to what sync_back would propagate on VimLeavePre. A
    -- reconstructed lockfile may differ in field set/formatting (vim.pack's
    -- schema is not pinned), producing a false git diff.
    local function sync_runtime_from_committed()
      local ok, err = vim.uv.fs_copyfile(lock_path, packlock.runtime_path())
      if not ok then
        vim.notify("vim.pack: failed to sync runtime from lockfile: " .. tostring(err), vim.log.levels.ERROR)
      end
    end

    local function finish_all()
      local cancelled = state.check_id ~= my_check_id
      state.restoring = false
      -- HEAD changed; drop tag cache so re-renders re-resolve installed tags.
      tag_cache = {}
      -- WARN: resume_sync MUST run regardless of intermediate failures;
      -- otherwise pause_count stays >0 for the rest of the session and all
      -- sync_back/sync_to calls silently bail. sync_runtime_from_committed
      -- must still run BEFORE resume_sync to avoid the next PackChanged
      -- clobbering the committed lockfile with pre-restore runtime state.
      local sync_ok, sync_err = pcall(sync_runtime_from_committed)
      packlock.resume_sync()
      local cross_ok, cross_err = pcall(packlock.sync_cross_profile)
      if not sync_ok then
        vim.notify("vim.pack: runtime sync failed: " .. tostring(sync_err), vim.log.levels.ERROR)
      end
      if not cross_ok then
        vim.notify("vim.pack: cross-profile sync failed: " .. tostring(cross_err), vim.log.levels.ERROR)
      end
      if cancelled then
        -- Window closed mid-restore; disk may be partially mutated.
        vim.notify(
          string.format(
            "vim.pack: restore cancelled (%d done, %d errors); lockfile is authoritative, re-run :Pack R to converge",
            restored,
            errors
          ),
          vim.log.levels.WARN
        )
        return
      end
      render()
      vim.notify(
        string.format("vim.pack: restored %d, skipped %d, errors %d", restored, skipped, errors),
        errors > 0 and vim.log.levels.WARN or vim.log.levels.INFO
      )
    end

    -- WARN: called both sync (skip/error path) and from vim.schedule (async
    -- path); safe because Lua for loop is single-threaded, so remaining only
    -- reaches 0 after all loop iterations have queued their callbacks.
    local function one_done()
      remaining = remaining - 1
      if remaining == 0 then
        finish_all()
      end
    end

    local function checkout(entry, path)
      vim.system({ "git", "-C", path, "checkout", "--quiet", entry.rev }, { text = true }, function(res)
        vim.schedule(function()
          if state.check_id ~= my_check_id then
            one_done()
            return
          end
          if res.code == 0 then
            restored = restored + 1
          else
            errors = errors + 1
            local git_err = vim.trim((res.stderr or "") ~= "" and res.stderr or (res.stdout or ""))
            vim.notify(
              string.format("vim.pack: %s checkout %s failed: %s", entry.name, entry.rev:sub(1, 7), git_err),
              vim.log.levels.ERROR
            )
          end
          one_done()
        end)
      end)
    end

    -- Check for uncommitted changes before checkout. Warn but proceed; git
    -- will refuse and surface a clear error if the working tree conflicts.
    -- WARN: --untracked-files=no — :helptags ALL generates doc/tags in every
    -- plugin and many upstreams don't .gitignore it, so untracked files are
    -- noise here. Only tracked-file modifications can be clobbered by checkout.
    local function with_dirty_check(entry, path)
      vim.system({ "git", "-C", path, "status", "--porcelain", "--untracked-files=no" }, { text = true }, function(res)
        vim.schedule(function()
          if state.check_id ~= my_check_id then
            one_done()
            return
          end
          if res.code == 0 and vim.trim(res.stdout) ~= "" then
            vim.notify(
              string.format("vim.pack: %s has uncommitted changes, attempting checkout anyway", entry.name),
              vim.log.levels.WARN
            )
          end
          checkout(entry, path)
        end)
      end)
    end

    for _, entry in ipairs(entries) do
      local path = installed[entry.name]
      if path and vim.uv.fs_stat(path) then
        with_dirty_check(entry, path)
      elseif entry.src then
        -- WARN: vim.pack.add is synchronous and runs inside this loop; with N
        -- missing plugins it blocks the UI for ~N clones. Acceptable since
        -- restores typically have 0–few missing entries (lockfile matches an
        -- already-installed set). If this changes, batch into a single add call.
        local spec = { src = entry.src, name = entry.name }
        if entry.version then
          spec.version = entry.version
        end
        local add_ok, add_err = pcall(vim.pack.add, { spec }, { load = false })
        if add_ok then
          local plugins = vim.pack.get({ entry.name }, { info = false })
          if plugins and plugins[1] and plugins[1].path and vim.uv.fs_stat(plugins[1].path) then
            with_dirty_check(entry, plugins[1].path)
          else
            errors = errors + 1
            vim.notify(string.format("vim.pack: %s installed but path missing", entry.name), vim.log.levels.ERROR)
            one_done()
          end
        else
          errors = errors + 1
          vim.notify(
            string.format("vim.pack: %s install failed: %s", entry.name, tostring(add_err)),
            vim.log.levels.ERROR
          )
          one_done()
        end
      else
        skipped = skipped + 1
        vim.notify(
          string.format("vim.pack: %s not installed and no src in lock, skipping", entry.name),
          vim.log.levels.WARN
        )
        one_done()
      end
    end
  end

  local function build_content()
    local plugins = vim.pack.get(nil, { info = false })

    local loaded = {}
    local not_loaded = {}
    for _, p in ipairs(plugins) do
      if p.active then
        table.insert(loaded, p)
      else
        table.insert(not_loaded, p)
      end
    end

    table.sort(loaded, function(a, b)
      return a.spec.name < b.spec.name
    end)
    table.sort(not_loaded, function(a, b)
      return a.spec.name < b.spec.name
    end)

    local lines = {}
    local hls = {} -- { line, col_start, col_end, hl_group }
    local line_to_plugin = {}
    local plugin_lines = {}

    local function add(text, hl)
      local lnum = #lines
      lines[#lines + 1] = text
      if hl then
        table.insert(hls, { lnum, 0, #text, hl })
      end
    end

    local function add_hl(lnum, col_start, col_end, hl)
      table.insert(hls, { lnum, col_start, col_end, hl })
    end

    local status = state.checking and "  (checking...)" or (state.restoring and "  (restoring...)" or "")
    local header = string.format(" vim.pack -- %d plugins | %d loaded%s", #plugins, #loaded, status)
    add(header, "PackUiHeader")

    local win_width = state.winid and api.nvim_win_get_width(state.winid) or 80
    local sep = " " .. string.rep("─", win_width - 1)
    add(sep, "PackUiSeparator")

    local bar = " [U]pdate All  [u] Update  [C]heck  [R]estore  [X] Clean  [D]elete  [L] Log  [?] Help"
    add(bar)
    -- gmatch () captures are 1-based; the end capture points one past the
    -- match — exactly the exclusive end_col extmarks expect.
    local lnum = #lines - 1
    for s, e in bar:gmatch("()%[.-%]()") do
      add_hl(lnum, s - 1, e - 1, "PackUiButton")
    end

    if state.show_help then
      add("")
      add(" Keymaps:", "PackUiHelp")
      add("   U       Update all plugins (opens confirm tab; :w to apply)", "PackUiHelp")
      add("   u       Update plugin under cursor (opens confirm tab; :w to apply)", "PackUiHelp")
      add("   C       Check remote for new commits", "PackUiHelp")
      add("   R       Restore all plugins to revisions in lockfile", "PackUiHelp")
      add("   X       Clean non-active plugins", "PackUiHelp")
      add("   D       Delete plugin under cursor (non-active only)", "PackUiHelp")
      add("   L       Open update log file", "PackUiHelp")
      add("   <CR>    Toggle plugin details", "PackUiHelp")
      add("   ]]      Jump to next plugin", "PackUiHelp")
      add("   [[      Jump to previous plugin", "PackUiHelp")
      add("   q/Esc   Close window", "PackUiHelp")
    end

    -- Max name width for alignment
    local max_name = 0
    for _, p in ipairs(plugins) do
      max_name = math.max(max_name, #p.spec.name)
    end

    -- Format: '   %s %s%s%s' => 3 spaces, icon, 1 space, name, pad, version
    -- Byte offsets: icon at 3, name at 3 + #icon_bytes + 1
    local function render_plugin(p, icon, hl_group)
      local name = p.spec.name
      local pad = string.rep(" ", max_name - #name + 2)
      local version = get_version_str(p)
      local has_semver = has_semver_version(version)
      local tag = has_semver and get_installed_tag(p.path) or nil
      local rev_short = p.rev and p.rev:sub(1, 7) or ""

      local ver_display = has_semver and (tag or (rev_short ~= "" and rev_short or version))
        or (rev_short ~= "" and rev_short or version)
      local latest = state.latest_ref[name]
      if latest then
        -- Normalize v-prefix before comparing to avoid spurious arrows when
        -- only the prefix differs (e.g. '1.2.3' vs 'v1.2.3').
        local cur_has_v = ver_display:match("^v") ~= nil
        local new_has_v = latest:match("^v") ~= nil
        local latest_display = latest
        if cur_has_v and not new_has_v then
          latest_display = "v" .. latest
        elseif not cur_has_v and new_has_v then
          latest_display = latest:sub(2)
        end
        if latest_display ~= ver_display then
          ver_display = ver_display .. " → " .. latest_display
        end
      end
      local update_count = state.updates[name] and #state.updates[name] or 0
      local update_str = update_count > 0 and string.format("  ↑%d", update_count) or ""
      local unreleased_count = state.unreleased[name] and #state.unreleased[name] or 0
      local unreleased_count_str = unreleased_count > 0 and string.format("  +%d unreleased", unreleased_count) or ""
      local unreleased = state.unreleased_breaking[name]
      local unreleased_str = unreleased
          and #unreleased > 0
          and string.format("  ⚠ %d breaking unreleased", #unreleased)
        or ""
      local line = string.format(
        "   %s %s%s%s%s%s%s",
        icon,
        name,
        pad,
        ver_display,
        update_str,
        unreleased_count_str,
        unreleased_str
      )
      local lnum_cur = #lines
      add(line)

      local icon_bytes = #icon
      local icon_start = 3
      local name_start = icon_start + icon_bytes + 1

      add_hl(lnum_cur, icon_start, icon_start + icon_bytes, hl_group)
      add_hl(lnum_cur, name_start, name_start + #name, hl_group)
      if #ver_display > 0 then
        local ver_start = name_start + #name + #pad
        local ver_hl = state.breaking[name] and "PackUiBreaking" or "PackUiVersion"
        add_hl(lnum_cur, ver_start, ver_start + #ver_display, ver_hl)
      end
      if update_count > 0 then
        local update_start = name_start + #name + #pad + #ver_display
        add_hl(
          lnum_cur,
          update_start,
          update_start + #update_str,
          state.breaking[name] and "PackUiBreaking" or "PackUiUpdateAvailable"
        )
      end
      if #unreleased_count_str > 0 then
        local unrel_count_start = name_start + #name + #pad + #ver_display + #update_str
        add_hl(lnum_cur, unrel_count_start, unrel_count_start + #unreleased_count_str, "PackUiUpdateAvailable")
      end
      if #unreleased_str > 0 then
        local unrel_start = name_start + #name + #pad + #ver_display + #update_str + #unreleased_count_str
        add_hl(lnum_cur, unrel_start, unrel_start + #unreleased_str, "PackUiBreaking")
      end

      -- 1-based line number for cursor operations
      line_to_plugin[lnum_cur + 1] = name
      plugin_lines[name] = lnum_cur + 1

      if state.expanded[name] then
        local details = {
          string.format("     Path:    %s", p.path),
          string.format("     Source:  %s", p.spec.src),
        }
        if p.rev then
          table.insert(details, string.format("     Rev:     %s", p.rev))
        end
        for _, d in ipairs(details) do
          add(d, "PackUiDetail")
          line_to_plugin[#lines] = name
        end
        local commits = state.updates[name]
        if commits and #commits > 0 then
          local max_commits = state.show_all_commits[name] and #commits or MAX_COMMITS_PREVIEW
          for i, c in ipairs(commits) do
            if i > max_commits then
              add(string.format("     ... and %d more (Enter to expand)", #commits - max_commits), "PackUiDetail")
              line_to_plugin[#lines] = name
              break
            end
            add("     " .. c, is_breaking_commit(c) and "PackUiBreaking" or nil)
            line_to_plugin[#lines] = name
          end
          add("")
        end
        local unrel = state.unreleased_breaking[name]
        local unreleased_commits = state.unreleased[name]
        if unreleased_commits and #unreleased_commits > 0 then
          add(string.format("     +%d unreleased commit(s) on main", #unreleased_commits), "PackUiUpdateAvailable")
          line_to_plugin[#lines] = name
          add("")
        end
        if unrel and #unrel > 0 then
          add(string.format("     ⚠ %d breaking change(s) unreleased on main:", #unrel), "PackUiBreaking")
          line_to_plugin[#lines] = name
          for _, c in ipairs(unrel) do
            add("       " .. c, "PackUiBreaking")
            line_to_plugin[#lines] = name
          end
          add("")
        end
      end
    end

    -- Loaded
    add("")
    add(string.format(" Loaded (%d)", #loaded), "PackUiSectionHeader")
    for _, p in ipairs(loaded) do
      render_plugin(p, "●", "PackUiPluginLoaded")
    end

    -- Not Loaded
    if #not_loaded > 0 then
      add("")
      add(string.format(" Not Loaded (%d)", #not_loaded), "PackUiSectionHeader")
      for _, p in ipairs(not_loaded) do
        render_plugin(p, "○", "PackUiPluginNotLoaded")
      end
    end

    state.line_to_plugin = line_to_plugin
    state.plugin_lines = plugin_lines

    return lines, hls
  end

  render = function()
    if not state.bufnr or not api.nvim_buf_is_valid(state.bufnr) then
      return
    end

    local lines, hls = build_content()

    vim.bo[state.bufnr].modifiable = true
    api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
    vim.bo[state.bufnr].modifiable = false
    vim.bo[state.bufnr].modified = false

    api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)
    for _, hl in ipairs(hls) do
      api.nvim_buf_set_extmark(state.bufnr, ns, hl[1], hl[2], {
        end_col = hl[3],
        hl_group = hl[4],
      })
    end
  end

  local function plugin_at_cursor()
    if not state.winid or not api.nvim_win_is_valid(state.winid) then
      return nil
    end
    local row = api.nvim_win_get_cursor(state.winid)[1]
    return state.line_to_plugin[row]
  end

  -- Reset transient UI state (called by both close() and WinClosed)
  local function reset_state()
    state.winid = nil
    state.bufnr = nil
    state.expanded = {}
    state.show_help = false
    clear_check_state()
    state.show_all_commits = {}
    state.checking = false
    state.restoring = false
    -- Invalidate any in-flight check_updates callbacks
    state.check_id = state.check_id + 1
    -- WARN: drop tag_cache too. close() is called before vim.pack.update(),
    -- which moves HEADs without firing our restore path, leaving cached tags
    -- stale on next :Pack open.
    tag_cache = {}
  end

  local function close()
    -- WARN: remove autocmd first to prevent it from corrupting state on re-open.
    if state.win_autocmd_id then
      pcall(api.nvim_del_autocmd, state.win_autocmd_id)
      state.win_autocmd_id = nil
    end
    if state.winid and api.nvim_win_is_valid(state.winid) then
      api.nvim_win_close(state.winid, true)
    end
    -- Buffer has bufhidden=wipe — wiped automatically when window closes.
    reset_state()
  end

  local function jump_plugin(direction)
    if not state.winid or not api.nvim_win_is_valid(state.winid) then
      return
    end
    local row = api.nvim_win_get_cursor(state.winid)[1]

    -- WARN: navigate by plugin_lines (header lines only). line_to_plugin
    -- maps every rendered row (including expanded details) to its owning
    -- plugin, so iterating it would step through detail rows.
    local plines = {}
    for _, lnum in pairs(state.plugin_lines) do
      table.insert(plines, lnum)
    end
    table.sort(plines)

    if direction > 0 then
      for _, lnum in ipairs(plines) do
        if lnum > row then
          api.nvim_win_set_cursor(state.winid, { lnum, 0 })
          return
        end
      end
      if #plines > 0 then
        api.nvim_win_set_cursor(state.winid, { plines[1], 0 })
      end
    else
      for i = #plines, 1, -1 do
        if plines[i] < row then
          api.nvim_win_set_cursor(state.winid, { plines[i], 0 })
          return
        end
      end
      if #plines > 0 then
        api.nvim_win_set_cursor(state.winid, { plines[#plines], 0 })
      end
    end
  end

  -- Forward decl: keymap closures reference open() before it's defined.
  -- Lua closures capture locals by reference, but the local must be declared
  -- in an enclosing scope at the point the closure is created.
  local open

  -- Buffer-local keymaps; survive re-focus since buffer persists.
  local function setup_keymaps()
    local buf = state.bufnr
    local opts = { buffer = buf, silent = true, nowait = true }

    vim.keymap.set("n", "q", close, opts)
    vim.keymap.set("n", "<Esc>", close, opts)

    -- WARN: vim.pack.update() opens a confirm buffer; user must `:w` to apply
    -- AND write the lockfile. Closing the confirm tab without `:w` leaves the
    -- lockfile stale even if some plugins were checked out previously.
    vim.keymap.set("n", "U", function()
      close()
      vim.pack.update()
    end, opts)

    vim.keymap.set("n", "u", function()
      local name = plugin_at_cursor()
      if name then
        close()
        vim.pack.update({ name })
      end
    end, opts)

    vim.keymap.set("n", "X", function()
      local to_clean = vim
        .iter(vim.pack.get(nil, { info = false }))
        :filter(function(x)
          return not x.active
        end)
        :map(function(x)
          return x.spec.name
        end)
        :totable()

      if #to_clean == 0 then
        vim.notify("vim.pack: nothing to clean", vim.log.levels.INFO)
        return
      end

      local msg = string.format("Remove %d non-active plugin(s)?\n\n%s", #to_clean, table.concat(to_clean, "\n"))
      local choice = vim.fn.confirm(msg, "&Yes\n&No", 2, "Question")
      if choice == 1 then
        close()
        local ok, err = pcall(vim.pack.del, to_clean)
        if ok then
          vim.notify(string.format("vim.pack: removed %d plugin(s)", #to_clean), vim.log.levels.INFO)
        else
          vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
        end
      end
    end, opts)

    -- Delete plugin under cursor
    vim.keymap.set("n", "D", function()
      local name = plugin_at_cursor()
      if not name then
        return
      end

      local pdata = vim.pack.get({ name }, { info = false })
      if #pdata == 0 then
        vim.notify(string.format("vim.pack: %s is not installed", name), vim.log.levels.WARN)
        return
      end
      if pdata[1].active then
        vim.notify(string.format("vim.pack: %s is active, remove from config first", name), vim.log.levels.WARN)
        return
      end

      local choice = vim.fn.confirm(string.format("Delete plugin %s?", name), "&Yes\n&No", 2, "Question")
      if choice == 1 then
        close()
        local del_ok, err = pcall(vim.pack.del, { name })
        if del_ok then
          vim.notify(string.format("vim.pack: removed %s", name), vim.log.levels.INFO)
        else
          vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
        end
      end
    end, opts)

    -- Open log
    vim.keymap.set("n", "L", function()
      close()
      local log_path = vim.fs.joinpath(vim.fn.stdpath("log"), "nvim-pack.log")
      if vim.uv.fs_stat(log_path) then
        vim.cmd.edit(log_path)
      else
        vim.notify("vim.pack: no log file yet", vim.log.levels.INFO)
      end
    end, opts)

    -- Toggle details: 3-state cycle when commits are truncated
    vim.keymap.set("n", "<CR>", function()
      local name = plugin_at_cursor()
      if name then
        local commits = state.updates[name]
        local has_truncated = commits and #commits > MAX_COMMITS_PREVIEW
        if not state.expanded[name] then
          state.expanded[name] = true
        elseif has_truncated and not state.show_all_commits[name] then
          state.show_all_commits[name] = true
        else
          state.expanded[name] = false
          state.show_all_commits[name] = nil
        end
        render()
        if state.plugin_lines[name] then
          api.nvim_win_set_cursor(state.winid, { state.plugin_lines[name], 0 })
        end
      end
    end, opts)

    vim.keymap.set("n", "]]", function()
      jump_plugin(1)
    end, opts)
    vim.keymap.set("n", "[[", function()
      jump_plugin(-1)
    end, opts)

    vim.keymap.set("n", "C", check_updates, opts)

    vim.keymap.set("n", "R", restore_from_lock, opts)

    vim.keymap.set("n", "?", function()
      state.show_help = not state.show_help
      render()
    end, opts)
  end

  open = function()
    -- Already open: focus it
    if state.winid and api.nvim_win_is_valid(state.winid) then
      api.nvim_set_current_win(state.winid)
      return
    end

    state.bufnr = api.nvim_create_buf(false, true)
    vim.bo[state.bufnr].buftype = "nofile"
    vim.bo[state.bufnr].bufhidden = "wipe"
    vim.bo[state.bufnr].swapfile = false
    vim.bo[state.bufnr].filetype = "pack-ui"

    local cols = vim.o.columns
    local lines = vim.o.lines
    local width = math.min(cols - 4, math.max(math.floor(cols * 0.8), 60))
    local height = math.min(lines - 4, math.max(math.floor(lines * 0.7), 20))
    local row = math.floor((lines - height) / 2)
    local col = math.floor((cols - width) / 2)

    state.winid = api.nvim_open_win(state.bufnr, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = " vim.pack ",
      title_pos = "center",
    })

    vim.wo[state.winid].cursorline = true
    vim.wo[state.winid].wrap = false

    render()
    setup_keymaps()

    -- Track WinClosed for external closes (:quit, <C-w>c). Store the autocmd
    -- ID so close() can remove it; otherwise re-opening immediately after an
    -- explicit close races on state.
    local captured_winid = state.winid
    state.win_autocmd_id = api.nvim_create_autocmd("WinClosed", {
      buffer = state.bufnr,
      once = true,
      callback = function(ev)
        if tonumber(ev.match) ~= captured_winid then
          return
        end
        state.win_autocmd_id = nil
        reset_state()
      end,
    })
  end

  api.nvim_create_user_command("Pack", function(opts)
    -- WARN: vim.pack.update() (no force) opens a confirm tab. The lockfile
    -- is only written after the user `:w`s that buffer. With bang, force=true
    -- skips confirmation and writes the lockfile immediately.
    if opts.args == "update" or opts.args == "update-all" then
      vim.pack.update(nil, { force = opts.bang })
      return
    end
    open()
    if opts.args == "check" then
      check_updates()
    end
  end, {
    nargs = "?",
    bang = true,
    complete = function()
      return { "check", "update", "update-all" }
    end,
    desc = "Open vim.pack plugin manager UI (use ! to update without confirm)",
  })

  setup_highlights()
end)
