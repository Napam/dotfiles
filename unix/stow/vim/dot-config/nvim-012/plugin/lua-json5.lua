-- Native module: install.sh needs a C/C++ compiler. Full profile only.
if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  -- Register PackChanged BEFORE vim.pack.add so it fires on first bootstrap.
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      if ev.data.spec.name == "lua-json5" then
        local plugin_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/lua-json5"
        local installer = plugin_dir .. "/install.sh"
        if vim.fn.filereadable(installer) == 1 then
          vim.notify("lua-json5: running install.sh ...")
          vim.system({ "sh", installer }, { cwd = plugin_dir }, function(out)
            vim.schedule(function()
              if out.code == 0 then
                vim.notify("lua-json5: build complete")
              else
                vim.notify("lua-json5: build failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
              end
            end)
          end)
        end
      end
    end,
  })

  vim.pack.add({
    { src = "https://github.com/Joakker/lua-json5" },
  })
end)
