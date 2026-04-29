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

  -- tree-sitter dependent plugins
  do
    if Config.use_treesitter_parser then
      -- Ensure Go parser exists before loading plugins that query treesitter.
      -- Helper is published by plugin/nvim_treesitter.lua at sourcing time.
      if not Config.ts.ensure_parser("go") then
        vim.notify(
          "lang/go: failed to ensure 'go' treesitter parser; "
          .. "goplements/blink-go-import may misbehave",
          vim.log.levels.WARN
        )
      end

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

  -- go-impl (uses "impl" from mason and "symbolScope", "symbolMatcher" setting in gopls)
  do
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
