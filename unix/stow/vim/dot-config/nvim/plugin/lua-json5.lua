-- Native module: install.sh needs a C/C++ compiler. Full profile only.
if Config.only_essential_plugins() then
  return
end

local pack_build = require("pack_build")

local PACK_NAME = "lua-json5"

local ensure = pack_build.setup(PACK_NAME, nil, { check_binary = "lua/json5.so" })

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/Joakker/lua-json5" },
  })

  ensure()
end)
