return {
  'chomosuke/typst-preview.nvim',
  lazy = false, -- or ft = 'typst'
  version = '1.*',
  opts = {
    extra_args = function(path_of_main_file)
      local main_dir = vim.fs.dirname(vim.fn.fnamemodify(path_of_main_file, ':p'))
      local font_dirs = vim.fs.find('fonts', {
        path = main_dir,
        upward = true,
        type = 'directory',
      })
      if #font_dirs > 0 then
        return { '--font-path', font_dirs[1] }
      end
      return {}
    end,
  },
}
