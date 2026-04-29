-- Public helpers exposed via Config.ts so other plugin files can install
-- treesitter parsers without reaching into nvim-treesitter directly. Defined
-- at sourcing time (top-level) so they are available to any plugin file's
-- on_vim_enter callback regardless of alphabetical load order.
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
--- true immediately if the parser is already on runtimepath. Otherwise installs
--- it synchronously via nvim-treesitter (up to 30s) and codesigns on macOS.
--- Safe to call from any plugin file's on_vim_enter callback; no dependency on
--- alphabetical sourcing order — lazily ensures nvim-treesitter itself is
--- available before invoking its install API.
---@param lang string parser/language name
---@return boolean success
function Config.ts.ensure_parser(lang)
  if not Config.use_nvim_treesitter then
    return false
  end
  -- Fast path: parser already loadable. Avoids loading nvim-treesitter at all
  -- on warm starts.
  if pcall(vim.treesitter.language.add, lang) then
    return true
  end
  -- Slow path: need nvim-treesitter. Ensure it is on runtimepath; this is a
  -- no-op if vim.pack.add has already added it earlier in this session.
  local ok_add = pcall(vim.pack.add, {
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  })
  if not ok_add then
    return false
  end
  local ok_ts, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok_ts or not parsers[lang] then
    return false
  end
  local ok_install = pcall(function()
    require("nvim-treesitter").install({ lang }):wait(30000)
  end)
  if ok_install then
    sign_parser_macos(lang)
  end
  return ok_install
end

if Config.use_nvim_treesitter then
  require("lazyload").on_vim_enter(function()
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

    -- Incremental selection (nvim-treesitter main has no built-in module; tiny custom impl).
    -- <C-space>: init / expand to parent node. <BS>: shrink to child node.
    -- Note: <C-space> in insert mode is bound by blink.cmp; this is normal/visual only.
    local sel_stack = {} ---@type table<integer, TSNode[]>

    local function get_bufnr() return vim.api.nvim_get_current_buf() end

    local function set_visual_from_node(node)
      local srow, scol, erow, ecol = node:range()
      vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
      vim.cmd("normal! v")
      -- end-exclusive in TS; move to last char inclusive
      if ecol == 0 then
        vim.api.nvim_win_set_cursor(0, { erow, math.huge })
      else
        vim.api.nvim_win_set_cursor(0, { erow + 1, ecol - 1 })
      end
    end

    local function init_selection()
      local node = vim.treesitter.get_node()
      if not node then return end
      sel_stack[get_bufnr()] = { node }
      set_visual_from_node(node)
    end

    local function node_incremental()
      local buf = get_bufnr()
      local stack = sel_stack[buf]
      if not stack or #stack == 0 then
        init_selection()
        return
      end
      local cur = stack[#stack]
      local parent = cur:parent()
      if not parent then
        set_visual_from_node(cur)
        return
      end
      table.insert(stack, parent)
      set_visual_from_node(parent)
    end

    local function node_decremental()
      local buf = get_bufnr()
      local stack = sel_stack[buf]
      if not stack or #stack <= 1 then
        if stack and stack[1] then set_visual_from_node(stack[1]) end
        return
      end
      table.remove(stack)
      set_visual_from_node(stack[#stack])
    end

    vim.keymap.set("n", "<C-space>", init_selection, { desc = "TS: init selection" })
    vim.keymap.set("x", "<C-space>", node_incremental, { desc = "TS: expand selection" })
    vim.keymap.set("x", "<BS>", node_decremental, { desc = "TS: shrink selection" })

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

    --- Auto-start treesitter highlighting for every buffer.
    --- Registered at plugin/ sourcing time (step 11) so it runs before LSP's
    --- FileType handlers (registered at VimEnter), preventing race conditions
    --- with plugins that use treesitter queries on LspAttach.
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

        if Config.ts.ensure_parser(lang) then
          pcall(vim.treesitter.start, bufnr, lang)
        end
      end,
    })
  end)
end
