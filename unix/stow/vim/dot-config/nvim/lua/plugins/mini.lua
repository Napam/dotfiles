return {
  {
    "echasnovski/mini.pairs",
    version = "*",
    config = function()
      require("mini.pairs").setup()
    end,
  },
  {
    "echasnovski/mini.surround",
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
    "echasnovski/mini.icons",
    opts = {}
  },
}
