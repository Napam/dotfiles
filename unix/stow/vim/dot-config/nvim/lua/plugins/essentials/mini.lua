return {
  {
    "nvim-mini/mini.pairs",
    version = "*",
    config = function()
      require("mini.pairs").setup()
    end,
  },
  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {
      mappings = {
        add = "S",      -- Add surrounding in Normal and Visual modes
        delete = "ds",  -- Delete surrounding
        replace = "cs", -- Replace surrounding
      },
    },
  },
  {
    "nvim-mini/mini.icons",
    opts = {}
  },
}
