if Config.only_essential_plugins() then
  return
end

require("lazyload").on_vim_enter(function()
  -- gotmpl/gohtml detection lives in plugin/filetype.lua (must run at startup);
  -- hard-tab opts live in after/ftplugin/{go,gomod,gowork,gotmpl}.lua, which
  -- fire for startup buffers too -- a FileType autocmd registered here at
  -- VimEnter misses the argv buffer, whose FileType fired before VimEnter.

  -- Tree-sitter dependent plugins (safe at setup; no parser query until use).
  if Config.use_treesitter_parser then
    vim.pack.add({
      { src = "https://github.com/maxandron/goplements.nvim" },
      { src = "https://github.com/edte/blink-go-import.nvim" },
    })
    require("goplements").setup()
    require("blink-go-import").setup()
  end

  -- WARN: go-impl calls vim.treesitter.query.parse("go", ...) at module-load
  -- (helper.lua, top-level), so go parser must be installed+loadable before
  -- require("go-impl"). Safe here: 0000_priority/0001_nvim-treesitter sourced first.
  if Config.use_treesitter_parser and Config.ts.ensure_parser("go") then
    vim.pack.add({
      { src = "https://github.com/fang2hou/go-impl.nvim" },
      { src = "https://github.com/MunifTanjim/nui.nvim" },
    })
    require("go-impl").setup({
      picker = "snacks",
      insert = {
        position = "after",
        before_newline = true,
        after_newline = false,
      },
    })
  end
end)
