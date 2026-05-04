-- No essentials gate: whichkey calls require("opencode") from keymap callbacks.
require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/nickjvandyke/opencode.nvim" },
  })

  ---@type opencode.Opts
  vim.g.opencode_opts = {}

  -- Post-setup mutation is safe: snacks.picker resolves actions/keymaps from
  -- its config table on each picker open, not at Snacks.setup() time.
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.config and snacks.config.picker then
    local pc = snacks.config.picker
    pc.actions = pc.actions or {}
    pc.actions.opencode_send = function(...)
      return require("opencode").snacks_picker_send(...)
    end
    pc.win = pc.win or {}
    pc.win.input = pc.win.input or {}
    pc.win.input.keys = pc.win.input.keys or {}
    pc.win.input.keys["<a-a>"] = { "opencode_send", mode = { "n", "i" } }
  end
end)
