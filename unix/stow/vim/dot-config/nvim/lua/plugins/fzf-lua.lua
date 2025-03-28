local fzf_lua = function(submodule)
  local module_path = table.concat({ "fzf-lua", submodule }, ".")
  return require(module_path)
end

return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  -- dependencies = { "nvim-tree/nvim-web-devicons" },
  -- or if using mini.icons/mini.nvim
  dependencies = { "echasnovski/mini.icons" },
  config = function()
    fzf_lua().setup({ "telescope" })
  end,
}
