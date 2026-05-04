if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/chomosuke/typst-preview.nvim", version = vim.version.range("1.*") },
  })

  require("typst-preview").setup({
    extra_args = function(path_of_main_file)
      local main_dir = vim.fs.dirname(vim.fn.fnamemodify(path_of_main_file, ":p"))
      local font_dirs = vim.fs.find("fonts", {
        path = main_dir,
        upward = true,
        type = "directory",
      })
      if #font_dirs > 0 then
        return { "--font-path", font_dirs[1] }
      end
      return {}
    end,
  })
end)
