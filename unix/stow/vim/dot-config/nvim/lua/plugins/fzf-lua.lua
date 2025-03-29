local fzf_lua = function(submodule)
  local module_path = table.concat({ "fzf-lua", submodule }, ".")
  return require(module_path)
end

return {
  "ibhagwan/fzf-lua",
  dependencies = { "echasnovski/mini.icons" },
  config = function()
  end,
}
