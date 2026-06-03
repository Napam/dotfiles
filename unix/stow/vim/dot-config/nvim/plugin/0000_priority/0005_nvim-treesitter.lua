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
    vim.notify(
      ("sign_parser_macos(%s): codesign failed (exit %d): %s"):format(parser_name, vim.v.shell_error, out),
      vim.log.levels.WARN
    )
  end
end

--- Idempotent parser install. Returns true if already loadable; otherwise
--- installs synchronously (≤30s, blocks UI), codesigns on macOS.
---@param lang string
---@return boolean success
function Config.ts.ensure_parser(lang)
  if not Config.use_nvim_treesitter then
    return false
  end

  -- WARN: do NOT pcall this. `language.add` returns `nil, errmsg` on missing
  -- parser (no throw), so `if pcall(...)` is always true and bypasses install.
  if vim.treesitter.language.add(lang) then
    return true
  end

  local ok_req, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok_req then
    vim.notify(
      ("ensure_parser(%s): nvim-treesitter.parsers not loadable: %s"):format(lang, parsers),
      vim.log.levels.WARN
    )
    return false
  end
  if not parsers[lang] then
    vim.notify(("ensure_parser(%s): no parser config registered for language"):format(lang), vim.log.levels.WARN)
    return false
  end

  -- WARN: without tree-sitter CLI, install Task completes "successfully" and
  -- :wait returns normally, masking the compile failure. Pre-flight check.
  if vim.fn.executable("tree-sitter") ~= 1 then
    vim.notify(
      ("ensure_parser(%s): `tree-sitter` CLI not on PATH; check mason installed `tree-sitter-cli`."):format(lang),
      vim.log.levels.WARN
    )
    return false
  end

  local ok_install, install_err = pcall(function()
    require("nvim-treesitter").install({ lang }):wait(30000)
  end)
  if not ok_install then
    vim.notify(("ensure_parser(%s): install failed: %s"):format(lang, install_err), vim.log.levels.WARN)
    return false
  end

  sign_parser_macos(lang)

  -- WARN: nvim-treesitter Task "succeeds" even on compile error (logged, not
  -- propagated). Strict verify: .so on disk, dlopens, queries parse.
  local parser_path = parser_so_path(lang)
  if vim.fn.filereadable(parser_path) ~= 1 then
    vim.notify(
      ("ensure_parser(%s): .so missing at %s after install (compile likely failed; :messages)"):format(
        lang,
        parser_path
      ),
      vim.log.levels.WARN
    )
    return false
  end

  if not pcall(vim.treesitter.language.add, lang) then
    vim.notify(("ensure_parser(%s): .so exists but failed to load (codesign/ABI?)"):format(lang), vim.log.levels.WARN)
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
  if #query_files == 0 then
    -- Fallback: probe disk directly. If the .scm exists but rtp scan won't
    -- find it, the file is still usable — vim.treesitter.start handles it.
    local scm = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "queries", lang, "highlights.scm")
    if vim.uv.fs_stat(scm) then
      -- Verify the query actually parses; fs_stat alone proves nothing.
      if pcall(vim.treesitter.query.get, lang, "highlights") then
        return true
      end
    end
    local query_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "queries", lang)
    local on_disk = vim.uv.fs_stat(query_dir) ~= nil
    vim.notify(
      ("ensure_parser(%s): no highlights.scm (queries dir on disk: %s)"):format(lang, tostring(on_disk)),
      vim.log.levels.WARN
    )
    return false
  end

  return true
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
    vim.notify(("packadd nvim-treesitter failed: %s"):format(pa_err), vim.log.levels.ERROR)
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
    -- Deferred so cold compile doesn't block first-buffer paint. See INJECTION_PARSERS above.
    for _, lang in ipairs(INJECTION_PARSERS) do
      Config.ts.ensure_parser(lang)
    end
  end)

  -- WARN: registered at sourcing (not VimEnter) so it runs before LSP's FileType
  -- handlers — avoids races with plugins using treesitter on LspAttach.
  -- ensure_parser blocks UI ≤30s on first encounter (typical 1-3s).
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

      if Config.ts.ensure_parser(lang) then
        pcall(vim.treesitter.start, bufnr, lang)
      end
    end,
  })
end
