-- Source-time load (after 0000_mason): puts nvim-treesitter on rtp + exposes
-- Config.ts.ensure_parser before any later plugin/ file is sourced.
Config.ts = Config.ts or {}

-- Injection-only parsers (never primary; FileType autocmd never installs them).
-- Pulled in via `; inject` from stock and queries/. Sources:
--   sql ← go/python   bash ← yaml         css ← templ/svelte   promql ← yaml
--   js/ts ← svelte    md ← python md(...) html ← ecma/markdown luadoc ← lua ---@
--   jsdoc/comment/regex/markdown_inline ← stock injections
local INJECTION_PARSERS = {
  "jsdoc",
  "comment",
  "regex",
  "markdown_inline",
  "markdown",
  "html",
  "luadoc",
  "sql",
  "bash",
  "css",
  "promql",
  "javascript",
  "typescript",
}

---@param lang string
---@return string
local function parser_so_path(lang)
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser", lang .. ".so")
end

---@param msg string
---@param level? integer
---@param opts? table
local function notify(msg, level, opts)
  -- fidget may not be loadable yet: this file sources before plugin/fidget.lua
  -- and fidget is skipped entirely in essential mode.
  local ok, fidget = pcall(require, "fidget.notification")
  if ok then
    return fidget.notify(msg, level, opts)
  end
  return vim.notify(msg, level, opts)
end

--- Sign parser .so on macOS to prevent code-signature crashes.
---@param parser_name string
local function sign_parser_macos(parser_name)
  if vim.fn.has("mac") ~= 1 then
    return
  end
  local parser_path = parser_so_path(parser_name)
  if vim.fn.filereadable(parser_path) ~= 1 then
    return
  end
  local out = vim.fn.system({ "codesign", "--force", "--sign", "-", parser_path })
  if vim.v.shell_error ~= 0 then
    notify(
      ("sign_parser_macos(%s): codesign failed (exit %d): %s"):format(parser_name, vim.v.shell_error, out),
      vim.log.levels.WARN
    )
  end
end

-- lang => install task while an install runs. Dedup: FileType can fire for
-- several buffers before the parser lands, and the injection prewarm runs at
-- VimEnter. Cleared by completion or the 60s stall guard.
local pending_install = {}
-- lang => { bufs = {number,...}, cbs = {fun(ok),...} } waiting on that install.
local waiting_install = {}

--- WARN + cb(false) for the sync error paths of ensure_parser. msg nil keeps
--- the failure silent (disabled-config path).
---@param cb? fun(ok: boolean)
---@param msg? string
local function fail_cb(cb, msg)
  if msg then
    notify(msg, vim.log.levels.WARN)
  end
  if cb then
    cb(false)
  end
end

--- Strict post-install verification. The install Task "succeeds" even on
--- compile error (logged, not propagated): .so on disk, dlopens, queries parse.
---@param lang string
---@return boolean
local function verify_parser_ready(lang)
  local parser_path = parser_so_path(lang)
  if vim.fn.filereadable(parser_path) ~= 1 then
    notify(
      ("ensure_parser(%s): .so missing at %s after install (compile likely failed; :messages)"):format(
        lang,
        parser_path
      ),
      vim.log.levels.WARN
    )
    return false
  end

  if not pcall(vim.treesitter.language.add, lang) then
    notify(("ensure_parser(%s): .so exists but failed to load (codesign/ABI?)"):format(lang), vim.log.levels.WARN)
    return false
  end

  -- Verify queries discoverable on rtp (highlights is canonical).
  -- WARN: nvim_get_runtime_file caches; freshly-installed query symlinks may
  -- not appear until rtp cache is busted. Re-set rtp to fire OptionSet, which
  -- invalidates both treesitter's query cache and the runtime path scanner.
  local function find_query()
    return vim.treesitter.query.get_files(lang, "highlights")
  end
  local query_files = find_query()
  if #query_files == 0 then
    -- WARN: assigning rtp to its current value still fires OptionSet runtimepath.
    vim.opt.rtp = vim.opt.rtp:get()
    vim.wait(500, function()
      query_files = find_query()
      return #query_files > 0
    end, 50)
  end
  local ready = #query_files > 0
  if not ready then
    -- Fallback: probe disk directly. If the .scm exists but rtp scan won't
    -- find it, the file is still usable — vim.treesitter.start handles it.
    local scm = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "queries", lang, "highlights.scm")
    if vim.uv.fs_stat(scm) then
      -- Verify the query actually parses; fs_stat alone proves nothing.
      ready = pcall(vim.treesitter.query.get, lang, "highlights")
    end
    if not ready then
      local query_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "queries", lang)
      local on_disk = vim.uv.fs_stat(query_dir) ~= nil
      notify(
        ("ensure_parser(%s): no highlights.scm (queries dir on disk: %s)"):format(lang, tostring(on_disk)),
        vim.log.levels.WARN
      )
    end
  end
  return ready
end

--- Idempotent, non-blocking parser install. Returns immediately; when the
--- parser becomes loadable (or install fails) it codesigns on macOS, verifies,
--- then starts treesitter on `bufnr` and calls `cb(ok)`.
---@param lang string
---@param bufnr? number buffer to start treesitter on once ready
---@param cb? fun(ok: boolean)
---@return boolean true if already loadable (install may still be pending)
function Config.ts.ensure_parser(lang, bufnr, cb)
  if not Config.use_nvim_treesitter then
    fail_cb(cb)
    return false
  end

  -- WARN: `language.add` returns `nil, errmsg` on a missing parser (no throw),
  -- but THROWS when the .so exists and dlopen fails. pcall alone can't tell
  -- the cases apart, so discriminate on both pcall status and the return.
  local ok_add, loaded = pcall(vim.treesitter.language.add, lang)
  if ok_add and loaded then
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.treesitter.start, bufnr, lang)
    end
    if cb then
      cb(true)
    end
    return true
  elseif not ok_add then
    fail_cb(cb, ("ensure_parser(%s): .so present but failed to load (codesign/ABI?)"):format(lang))
    return false
  end
  -- Missing parser (add returned nil, errmsg): fall through to install.

  if pending_install[lang] then
    local w = waiting_install[lang]
    if bufnr then
      w.bufs[#w.bufs + 1] = bufnr
    end
    if cb then
      w.cbs[#w.cbs + 1] = cb
    end
    return false
  end

  local ok_req, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok_req then
    fail_cb(cb, ("ensure_parser(%s): nvim-treesitter.parsers not loadable: %s"):format(lang, parsers))
    return false
  end
  if not parsers[lang] then
    fail_cb(cb, ("ensure_parser(%s): no parser config registered for language"):format(lang))
    return false
  end

  -- WARN: without tree-sitter CLI, install Task completes "successfully" and
  -- :wait returns normally, masking the compile failure. Pre-flight check.
  if vim.fn.executable("tree-sitter") ~= 1 then
    fail_cb(
      cb,
      ("ensure_parser(%s): `tree-sitter` CLI not on PATH; check mason installed `tree-sitter-cli`."):format(lang)
    )
    return false
  end

  local wait = { bufs = bufnr and { bufnr } or {}, cbs = cb and { cb } or {} }
  waiting_install[lang] = wait
  notify(("treesitter: installing %s parser…"):format(lang), vim.log.levels.INFO)
  local ok_task, task = pcall(require("nvim-treesitter").install, { lang })
  if not ok_task then
    if waiting_install[lang] == wait then
      waiting_install[lang] = nil
    end
    fail_cb(cb, ("ensure_parser(%s): install failed: %s"):format(lang, tostring(task)))
    return false
  end
  pending_install[lang] = task
  -- WARN: no :wait cap anymore (that was the UI-blocking part); guard against
  -- a hung compile leaving pending_install set forever, which would make
  -- future FileType events queue silently. Stall clears dedup only; a late
  -- completion still processes waiters.
  vim.defer_fn(function()
    if pending_install[lang] == task then
      pending_install[lang] = nil
      notify(
        ("ensure_parser(%s): install exceeded 60s; will retry on next FileType"):format(lang),
        vim.log.levels.WARN
      )
    end
  end, 60000)
  task:await(function(err, ok)
    vim.schedule(function()
      -- WARN: identity-guard both clears: the 60s stall guard may have
      -- cleared pending_install and a newer install may have taken over
      -- waiting_install while this task was hung. Never clobber its state.
      if pending_install[lang] == task then
        pending_install[lang] = nil
      end
      if waiting_install[lang] == wait then
        waiting_install[lang] = nil
      end
      if err or not ok then
        notify(
          ("ensure_parser(%s): install failed: %s"):format(lang, tostring(err or "install returned failure")),
          vim.log.levels.WARN
        )
        for _, c in ipairs(wait.cbs) do
          pcall(c, false)
        end
        return
      end
      sign_parser_macos(lang)
      if not verify_parser_ready(lang) then
        for _, c in ipairs(wait.cbs) do
          pcall(c, false)
        end
        return
      end
      -- Replace the "installing" INFO; must stay the last notify on success.
      notify(("treesitter: %s parser ready"):format(lang), vim.log.levels.INFO)
      for _, b in ipairs(wait.bufs) do
        if vim.api.nvim_buf_is_valid(b) then
          pcall(vim.treesitter.start, b, lang)
        end
      end
      for _, c in ipairs(wait.cbs) do
        pcall(c, true)
      end
    end)
  end)
  return false
end

if Config.use_nvim_treesitter then
  vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  })

  -- WARN: vim.pack.add during init.lua sourcing only does :packadd! (rtp only,
  -- no plugin/ source) — see :h vim.pack.add() `load` default. Without this,
  -- nvim-treesitter's user commands (:TSInstall etc.) and any plugin-time
  -- registration aren't available until :packloadall fires before VimEnter.
  -- Force source now so ensure_parser sees a fully-initialized plugin.
  local ok_pa, pa_err = pcall(vim.cmd.packadd, "nvim-treesitter")
  if not ok_pa then
    notify(("packadd nvim-treesitter failed: %s"):format(pa_err), vim.log.levels.ERROR)
  end

  -- HACK: silence nvim-treesitter's per-parser install chatter ("Installing
  -- parser", "Language installed", "Downloading ..."). Emitted via nvim_echo
  -- from log.lua's Logger:info — no config knob, so neuter the method.
  -- warn/error still surface.
  local ok_log, log = pcall(require, "nvim-treesitter.log")
  if ok_log and log and log.Logger then
    log.Logger.info = function() end
  end

  require("nvim-treesitter-textobjects").setup({
    select = {
      lookahead = true,
      include_surrounding_whitespace = false,
    },
    move = {
      set_jumps = true,
    },
  })

  local select_map = {
    ["af"] = { "@function.outer", desc = "a function" },
    ["if"] = { "@function.inner", desc = "inner function" },
    ["al"] = { "@loop.outer", desc = "a loop" },
    ["il"] = { "@loop.inner", desc = "inner loop" },
    ["ac"] = { "@class.outer", desc = "a class" },
    ["ic"] = { "@class.inner", desc = "inner class" },
    ["ai"] = { "@conditional.outer", desc = "a conditional" },
    ["ii"] = { "@conditional.inner", desc = "inner conditional" },
    ["ak"] = { "@comment.outer", desc = "a comment" },
    ["ik"] = { "@comment.inner", desc = "inner comment" },
    ["aj"] = { "@cell", desc = "a cell" },
    ["ij"] = { "@cellcontent", desc = "inner cell" },
  }
  for lhs, spec in pairs(select_map) do
    vim.keymap.set({ "x", "o" }, lhs, function()
      require("nvim-treesitter-textobjects.select").select_textobject(spec[1], "textobjects")
    end, { desc = spec.desc })
  end

  -- Incremental selection via `n` (next sibling) textobject. Visual maps re-issue
  -- the textobject without leading `v`; nvim_feedkeys "v" is sync, treats keys as typed.
  -- WARN: don't bind <Tab>/<S-Tab> — <Tab> shares keycode 0x09 with <C-i> and
  -- shadows jumplist-forward even under CSI-u.
  vim.keymap.set("n", "<C-space>", ":normal van<CR>", { silent = true, desc = "TS: select around (expand)" })
  vim.keymap.set("x", "<C-space>", function()
    vim.api.nvim_feedkeys("an", "v", false)
  end, { desc = "TS: expand selection" })
  vim.keymap.set("n", "<BS>", ":normal vin<CR>", { silent = true, desc = "TS: select inside (shrink)" })
  vim.keymap.set("x", "<BS>", function()
    vim.api.nvim_feedkeys("in", "v", false)
  end, { desc = "TS: shrink selection" })

  -- Custom parsers not shipped with nvim-treesitter.
  local custom_parsers = {
    {
      lang = "fga",
      register = { "fga", "fga" },
      config = {
        install_info = {
          url = "https://github.com/matoous/tree-sitter-fga",
          branch = "main",
          generate = false,
          queries = "queries",
        },
      },
    },
    {
      lang = "godoc",
      register = { "godoc", "godoc" },
      config = {
        install_info = {
          url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
          branch = "main",
          generate = false,
          queries = "queries",
        },
      },
    },
  }

  for _, p in ipairs(custom_parsers) do
    vim.treesitter.language.register(unpack(p.register))
  end

  local function inject_custom_parsers()
    local parsers = require("nvim-treesitter.parsers")
    for _, p in ipairs(custom_parsers) do
      parsers[p.lang] = p.config
    end
  end

  inject_custom_parsers()

  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = inject_custom_parsers,
  })

  require("lazyload").on_vim_enter(function()
    -- Async installs; cold bootstrap compiles run in the background, UI never
    -- blocks. See INJECTION_PARSERS above for why these exist.
    for _, lang in ipairs(INJECTION_PARSERS) do
      Config.ts.ensure_parser(lang)
    end
  end)

  -- WARN: registered at sourcing (not VimEnter) so it runs before LSP's FileType
  -- handlers — avoids races with plugins using treesitter on LspAttach.
  -- ensure_parser is async; a missing parser installs in the background and
  -- this buffer gets treesitter started when it lands.
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
    callback = function(event)
      local bufnr = event.buf
      local ft = event.match
      if ft == "" then
        return
      end

      local lang = vim.treesitter.language.get_lang(ft)
      if not lang then
        return
      end

      local ok = pcall(vim.treesitter.start, bufnr, lang)
      if ok then
        return
      end

      -- get_lang() falls back to ft for unmapped FTs (plugin floats: blink-cmp-menu,
      -- msg, ...). Skip langs nvim-treesitter doesn't know to avoid :messages spam.
      local parsers = require("nvim-treesitter.parsers")
      if not parsers[lang] then
        return
      end

      Config.ts.ensure_parser(lang, bufnr)
    end,
  })
end
