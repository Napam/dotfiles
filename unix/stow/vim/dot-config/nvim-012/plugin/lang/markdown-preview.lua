-- Browser-preview alternative to render-markdown.nvim (in-buffer).
-- Build hook runs upstream app/install.sh to fetch a pre-built binary.
-- Without the binary the plugin falls back to `node app/index.js`, which
-- requires `node_modules/tslib` that install.sh does not provide.
if Config.only_essential_plugins() then return end

local app_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/markdown-preview.nvim/app"

local function binary_present()
  return #vim.fn.glob(app_dir .. "/bin/markdown-preview-*", false, true) > 0
end

local function run_installer(reason)
  local installer = app_dir .. "/install.sh"
  if vim.fn.executable(installer) ~= 1 then
    vim.notify("markdown-preview: install.sh not found at " .. installer, vim.log.levels.WARN)
    return
  end
  vim.notify("markdown-preview: running app/install.sh (" .. reason .. ") ...")
  vim.system({ installer }, { cwd = app_dir }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        vim.notify("markdown-preview: install.sh failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
      elseif not binary_present() then
        vim.notify("markdown-preview: install.sh succeeded but no binary in app/bin (unsupported platform?)", vim.log.levels.ERROR)
      else
        vim.notify("markdown-preview: build complete")
      end
    end)
  end)
end

-- Register PackChanged eagerly (top-level, not inside on_vim_enter) so it
-- definitely fires on first bootstrap regardless of when vim.pack.add runs.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name ~= "markdown-preview.nvim" then return end
    run_installer("PackChanged")
  end,
})

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/iamcco/markdown-preview.nvim" },
  })

  -- Safety net: PackChanged only fires on install/update. If the plugin dir
  -- exists from a prior startup but the binary is missing (hook missed, prior
  -- install.sh failure, etc.), repair it here.
  if not binary_present() then
    run_installer("missing binary")
  end

  vim.g.mkdp_filetypes = { "markdown" }
end)
