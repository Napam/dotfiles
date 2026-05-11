---@brief
--- https://github.com/sveltejs/language-tools/tree/master/packages/language-server
--- Cross-file refs (.ts ↔ .svelte) need typescript-svelte-plugin in vtsls.
--- See after/lsp/vtsls.lua.

-- WARN: module-level. Inside on_attach with clear=true would wipe handlers
-- from prior (client, buf) attaches.
local augroup = vim.api.nvim_create_augroup("lspconfig.svelte", { clear = true })

---@type vim.lsp.Config
return {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  settings = {
    typescript = {
      inlayHints = {
        parameterNames = {
          enabled = "literals",
          suppressWhenArgumentMatchesName = true,
        },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    -- WARN: Svelte LSP only supports file:// schema. https://github.com/sveltejs/language-tools/issues/2777
    if vim.uv.fs_stat(fname) ~= nil then
      -- Tiered: lockfile root, fall back to .git. Nested = vim.fs.root priority syntax.
      local root_markers =
        { { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock", "deno.lock" }, ".git" }
      on_dir(vim.fs.root(bufnr, root_markers) or vim.fn.getcwd())
    end
  end,
  on_attach = function(client, bufnr)
    -- HACK: notify svelteserver to reload TS files. https://github.com/sveltejs/language-tools/issues/2008
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      group = augroup,
      callback = function(ctx)
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
    vim.api.nvim_buf_create_user_command(bufnr, "LspMigrateToSvelte5", function()
      client:exec_cmd({
        title = "Migrate Component to Svelte 5 Syntax",
        command = "migrate_to_svelte_5",
        arguments = { vim.uri_from_bufnr(bufnr) },
      })
    end, { desc = "Migrate Component to Svelte 5 Syntax" })
  end,
}
