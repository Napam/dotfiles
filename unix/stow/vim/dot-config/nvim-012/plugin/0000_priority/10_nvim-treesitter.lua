-- Source-time load (after 0000_priority/00_mason): nvim-treesitter on rtp,
-- custom parsers injected, treesitter-start FileType autocmd registered, and
-- Config.ts.ensure_parser exposed before any later plugin/ file is sourced.
-- See README "0000_priority/ load order".
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

--- Ensure a treesitter parser is installed and loadable. Idempotent: returns
--- true immediately if the parser is already loadable. Otherwise ensures
--- nvim-treesitter is on rtp, installs the parser synchronously (≤30s,
--- blocks UI on first install), and codesigns the .so on macOS.
---@param lang string parser/language name
---@return boolean success
function Config.ts.ensure_parser(lang)
  if not Config.use_nvim_treesitter then
    return false
  end

  -- Fast path: parser already loadable / already on rtp.
  -- NOTE: do NOT use `pcall(vim.treesitter.language.add, lang)` here:
  -- `language.add` does NOT throw when the parser is missing — it returns
  -- `nil, errmsg`. `pcall` returns true (no error thrown) regardless, so
  -- `if pcall(...) then` is always true and bypasses the install logic
  -- below. Check the actual return value instead.
  if vim.treesitter.language.add(lang) then
    return true
  end

  -- Slow path: ensure nvim-treesitter is on rtp (no-op if already added).
  local ok_add, add_err = pcall(vim.pack.add, {
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  })
  if not ok_add then
    vim.notify(
      ("ensure_parser(%s): vim.pack.add failed: %s"):format(lang, add_err),
      vim.log.levels.WARN
    )
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
    vim.notify(
      ("ensure_parser(%s): no parser config registered for language"):format(lang),
      vim.log.levels.WARN
    )
    return false
  end

  -- Pre-flight: tree-sitter CLI must be on PATH. Without it, nvim-treesitter's
  -- compile step returns an error string instead of throwing, the async Task
  -- completes "successfully", and `:wait` returns normally — masking failure.
  if vim.fn.executable("tree-sitter") ~= 1 then
    vim.notify(
      ("ensure_parser(%s): `tree-sitter` CLI not on PATH; cannot compile parser. "
        .. "Check that mason successfully installed `tree-sitter-cli`."):format(lang),
      vim.log.levels.WARN
    )
    return false
  end

  local ok_install, install_err = pcall(function()
    require("nvim-treesitter").install({ lang }):wait(30000)
  end)
  if not ok_install then
    vim.notify(
      ("ensure_parser(%s): install failed: %s"):format(lang, install_err),
      vim.log.levels.WARN
    )
    return false
  end

  sign_parser_macos(lang)

  -- Strict verification: nvim-treesitter's async Task completes "successfully"
  -- even when the underlying compile errored (logged but not propagated).
  -- Verify on disk + via the API consumers actually use.

  -- 1. .so on disk.
  local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. lang .. ".so"
  if vim.fn.filereadable(parser_path) ~= 1 then
    vim.notify(
      ("ensure_parser(%s): .so not found at %s after install (compile likely failed; check :messages)")
        :format(lang, parser_path),
      vim.log.levels.WARN
    )
    return false
  end

  -- 2. Parser dlopens.
  if not pcall(vim.treesitter.language.add, lang) then
    vim.notify(
      ("ensure_parser(%s): .so exists but failed to load (codesign/ABI issue?)"):format(lang),
      vim.log.levels.WARN
    )
    return false
  end

  -- 3. query.parse works — what consumers like go-impl call at module-load.
  -- Empty query is valid and exercises the queries directory + parser .so.
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
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      if ev.data.spec.name == "nvim-treesitter" then
        vim.cmd("TSUpdate")
      end
    end,
  })

  vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter",             version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  })

  -- nvim-treesitter-textobjects (main branch): per-keymap API.
  require("nvim-treesitter-textobjects").setup({
    select = {
      lookahead = true,
      include_surrounding_whitespace = false,
    },
    move = {
      set_jumps = true,
    },
  })

  -- Textobject select keymaps (mirrors old master-branch config).
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

  -- Incremental selection via the `n` (next sibling) textobject.
  -- <Tab>: select around / expand outward. <S-Tab>: select inside / shrink.
  -- Visual-mode mappings re-issue the textobject motion (no leading `v` —
  -- already in visual). Uses `nvim_feedkeys` with mode "v" so the keys are
  -- treated as if typed (not remapped) and run synchronously.
  vim.keymap.set("n", "<Tab>", ":normal van<CR>", { silent = true, desc = "TS: select around (expand)" })
  vim.keymap.set("x", "<Tab>", function()
    vim.api.nvim_feedkeys("an", "v", false)
  end, { desc = "TS: expand selection" })
  vim.keymap.set("n", "<S-Tab>", ":normal vin<CR>", { silent = true, desc = "TS: select inside (shrink)" })
  vim.keymap.set("x", "<S-Tab>", function()
    vim.api.nvim_feedkeys("in", "v", false)
  end, { desc = "TS: shrink selection" })

  --- Custom parsers not shipped with nvim-treesitter.
  --- Each entry: { lang = "name", register = { lang, ft }, config = { install_info = { ... } } }
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
  end)

  --- Auto-start treesitter highlighting. Registered at sourcing time so it
  --- runs before LSP's FileType handlers (registered at VimEnter), preventing
  --- races with plugins that use treesitter queries on LspAttach.
  ---
  --- NOTE: the `ensure_parser` call below blocks the UI for up to 30s on the
  --- first encounter of a new language (synchronous compile via tree-sitter
  --- CLI). This is by design — the alternative is opening a file and getting
  --- no highlighting until a later edit retriggers FileType. The 30s budget
  --- is a worst case; typical compiles are 1-3s.
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

      -- Skip langs nvim-treesitter doesn't know about. get_lang() falls back
      -- to the ft name for unmapped FTs (plugin UI floats like "blink-cmp-
      -- menu", "msg", etc.), which would spam :messages otherwise. parsers
      -- module is cached after first require.
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
