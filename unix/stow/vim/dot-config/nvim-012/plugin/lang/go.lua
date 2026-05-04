if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  -- filetypes
  do
    vim.filetype.add({
      extension = {
        gotmpl = "gotmpl",
        gohtml = "gotmpl",
      },
      pattern = {
        [".*%.go%.tmpl"] = "gotmpl",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "go", "gomod", "gowork", "gohtml", "gotmpl" },
      callback = function()
        vim.opt_local.expandtab = false
      end,
    })
  end

  -- tree-sitter dependent plugins (lazy: don't query parser at setup time)
  do
    if Config.use_treesitter_parser then
      vim.pack.add({
        { src = "https://github.com/maxandron/goplements.nvim" },
      })
      require("goplements").setup()

      vim.pack.add({
        { src = "https://github.com/edte/blink-go-import.nvim" },
      })
      require("blink-go-import").setup()
    end
  end

  -- go-impl calls vim.treesitter.query.parse("go", ...) at module-load
  -- (helper.lua, top-level), so Go parser must be installed+loadable before
  -- require("go-impl"). Safe here: 0000_priority/10_nvim-treesitter sourced
  -- first (see README load order). Also uses "impl" mason tool + gopls
  -- symbolScope/symbolMatcher.
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
