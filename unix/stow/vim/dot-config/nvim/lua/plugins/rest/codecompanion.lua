return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "franco-ruggeri/codecompanion-spinner.nvim",
  },
  config = function()
    require("codecompanion").setup({
      ignore_warnings = true,
      extensions = {
        spinner = {}
      },
      strategies = {
        chat = {
          adapter = {
            name = "copilot",
            model = "claude-sonnet-4.6"
          }
        }
      }
    })
  end,
}
