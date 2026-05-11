vim.pack.add({
  { src = "https://github.com/A7Lavinraj/fyler.nvim" },
})

require("fyler").setup({
  views = {
    finder = {
      win = {
        win_opts = {
          number = true,
          relativenumber = true,
        },
      },
    },
  },
})
