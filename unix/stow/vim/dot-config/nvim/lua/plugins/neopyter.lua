return {
  "SUSTech-data/neopyter",
  dependencies = {
    'nvim-lua/plenary.nvim',
    'AbaoFromCUG/websocket.nvim', -- for mode='direct'
    'nvim-treesitter/nvim-treesitter',
  },

  ---@type neopyter.Option
  opts = {
    mode = "direct",
    remote_address = "127.0.0.1:9001",
    file_pattern = { "*.ju.*" },
    on_attach = function(bufnr)
      -- do some buffer keymap
    end,
  },
}
