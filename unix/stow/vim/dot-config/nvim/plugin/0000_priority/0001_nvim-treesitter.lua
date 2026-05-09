-- Source-time load (after 00_mason): puts nvim-treesitter on rtp + exposes
-- Config.ts.ensure_parser before any later plugin/ file is sourced. See README.
Config.ts = Config.ts or {}

--- Sign a parser .so on macOS to prevent code-signature crashes.
---@param parser_name string
local function sign_parser_macos(parser_name)
  if vim.fn.has("mac") ~= 1 then
    return
  end
  local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. parser_name .. ".so"
  if vim.fn.filereadable(parser_path) == 1 then
    vim.fn.system({ "codesign", "--force", "--sign", "-", parser_path })
  end
end

--- Idempotent parser install. Returns true if already loadable; otherwise
--- ensures nvim-treesitter is on rtp, installs synchronously (≤30s, blocks UI),
--- codesigns on macOS.
---@param lang string
---@return boolean success
function Config.ts.ensure_parser(lang)
  if not Config.use_nvim_treesitter then
    return false
  end

  -- WARN: do NOT wrap this in pcall. `language.add` returns `nil, errmsg` on
  -- missing parser (no throw), so `if pcall(...)` is always true and bypasses
  -- the install logic below.
  if vim.treesitter.language.add(lang) then
    return true
  end

  local ok_add, add_err = pcall(vim.pack.add, {
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  })
  if not ok_add then
    vim.notify(("ensure_parser(%s): vim.pack.add failed: %s"):format(lang, add_err), vim.log.levels.WARN)
    return false
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

  -- WARN: without tree-sitter CLI, nvim-treesitter's compile returns an error
  -- string instead of throwing — the async Task completes "successfully" and
  -- :wait returns normally, masking failure. Pre-flight check.
  if vim.fn.executable("tree-sitter") ~= 1 then
    vim.notify(
      (
        "ensure_parser(%s): `tree-sitter` CLI not on PATH; cannot compile parser. "
        .. "Check that mason successfully installed `tree-sitter-cli`."
      ):format(lang),
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

  -- WARN: nvim-treesitter's Task completes "successfully" even when the
  -- compile errored (logged but not propagated). Strict verify: .so on disk,
  -- dlopens, queries parse.
  local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. lang .. ".so"
  if vim.fn.filereadable(parser_path) ~= 1 then
    vim.notify(
      ("ensure_parser(%s): .so not found at %s after install (compile likely failed; check :messages)"):format(
        lang,
        parser_path
      ),
      vim.log.levels.WARN
    )
    return false
  end

  if not pcall(vim.treesitter.language.add, lang) then
    vim.notify(
      ("ensure_parser(%s): .so exists but failed to load (codesign/ABI issue?)"):format(lang),
      vim.log.levels.WARN
    )
    return false
  end

  -- Empty query exercises the queries directory + parser .so (what
  -- consumers like go-impl call at module-load).
  if not pcall(vim.treesitter.query.parse, lang, "") then
    vim.notify(
      ("ensure_parser(%s): parser loaded but query.parse failed (queries missing?)"):format(lang),
      vim.log.levels.WARN
    )
    return false
  end

  return true
end

if Config.use_nvim_treesitter then
  -- WARN: PackChanged fires during vim.pack.add's clone phase, BEFORE the
  -- newly-added plugin's plugin/*.lua is sourced. Calling :TSUpdate inline
  -- raises E492 (command not yet registered). Defer to next tick so the
  -- vim.pack.add call frame unwinds and rtp sourcing completes first.
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      if ev.data.spec.name == "nvim-treesitter" then
        vim.defer_fn(function()
          vim.cmd("TSUpdate")
        end, 0)
      end
    end,
  })

  vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  })

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

  -- Incremental selection via `n` (next sibling) textobject.
  -- Visual maps re-issue the textobject with no leading `v` (already in visual);
  -- nvim_feedkeys mode "v" runs synchronously and treats keys as typed (not remapped).
  -- WARN: do not bind <Tab>/<S-Tab> here — <Tab> shares keycode 0x09 with <C-i>
  -- and shadows the jumplist-forward built-in even under CSI-u.
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
    require("treesitter-context").setup({
      multiwindow = true,
    })

    -- Injection-only parsers: never primary for any filetype, so the FileType
    -- autocmd below never installs them. Pulled in via `; inject` from other
    -- parsers and our queries/ (sql ← go/python, bash ← yaml, css ← templ,
    -- promql ← yaml, jsdoc/comment/regex/markdown_inline ← stock injections).
    -- Without these the host language's comments/strings render as one flat highlight.
    -- Deferred to VimEnter so cold-compile doesn't block first-buffer paint.
    for _, lang in ipairs({
      "jsdoc",
      "comment",
      "regex",
      "markdown_inline",
      "sql",
      "bash",
      "css",
      "promql",
    }) do
      Config.ts.ensure_parser(lang)
    end
  end)

  -- WARN: registered at sourcing time (not VimEnter) so it runs before LSP's
  -- FileType handlers, preventing races with plugins that use treesitter
  -- queries on LspAttach. ensure_parser below blocks UI up to 30s on first
  -- encounter of a new language (typical 1-3s).
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

      -- get_lang() falls back to the ft name for unmapped FTs (plugin UI floats
      -- like "blink-cmp-menu", "msg"). Skip langs nvim-treesitter doesn't know
      -- to avoid spamming :messages. parsers module is cached after first require.
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
