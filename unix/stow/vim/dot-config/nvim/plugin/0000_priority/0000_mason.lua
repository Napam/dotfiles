-- Source-time load (not on_vim_enter): mason bin must be on PATH before
-- sibling 0000_priority/ files spawn binaries.
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/zapling/mason-lock.nvim" },
})

-- WARN: prepend so mason bins shadow stale system bins (e.g. system tree-sitter).
require("mason").setup({ PATH = "prepend" })
require("mason-lock").setup({})
-- automatic_enable=false: vim.lsp.enable() handled in plugin/lsp.lua. Kept for
-- the mason<->lspconfig name aliases (e.g. :MasonInstall lua_ls -> lua-language-server).
require("mason-lspconfig").setup({ automatic_enable = false })

local mason_registry = require("mason-registry")

-- Sync-bootstrap tools needed before background install completes. Only
-- tree-sitter-cli today: required by Config.ts.ensure_parser
-- (10_nvim-treesitter.lua); without it the first parser compile silently
-- fails (mise doesn't ship tree-sitter; mason's CLI isn't on PATH yet).
-- Cost: ~15s refresh + ~5-15s install on FIRST launch only; subsequent runs
-- short-circuit on the 24h registry TTL + pkg:is_installed().
local critical_sync = { "tree-sitter-cli" }

local refreshed = false
mason_registry.refresh(function()
  refreshed = true
end)
if not vim.wait(15000, function()
  return refreshed
end, 50) then
  vim.notify("mason: registry refresh timed out (15s)", vim.log.levels.WARN)
end

for _, name in ipairs(critical_sync) do
  local ok, pkg = pcall(mason_registry.get_package, name)
  if ok and not pkg:is_installed() then
    local done = false
    pkg:install({}, function(success, err)
      done = true
      if not success then
        vim.notify(("mason: failed to install %q: %s"):format(name, err), vim.log.levels.ERROR)
      end
    end)
    if not vim.wait(60000, function()
      return done
    end, 100) then
      vim.notify(("mason: install of %q timed out (60s); continuing"):format(name), vim.log.levels.ERROR)
    end
  end
end

-- Background install. essentials = pre-built binaries (no node/cargo/go/python
-- build) so the essentials profile boots on a bare machine. extras add when
-- not in essentials-only profile. tree-sitter-cli handled in critical_sync above.
-- WARN: stylua's mason installer requires `unzip` on PATH; bare VMs may lack
-- it. Kept in extras (not essentials) so essentials boots cleanly.
local ensure_installed = {
  "actionlint",
  "hadolint",
  "lua-language-server",
  "shellcheck",
  "shfmt",
  "taplo",
}

if not Config.only_essential_plugins() then
  vim.list_extend(ensure_installed, {
    "api-linter",
    "basedpyright",
    "bash-language-server",
    "biome",
    "buf",
    "codelldb",
    "debugpy",
    "delve",
    "dockerfile-language-server",
    "eslint-lsp",
    "golangci-lint",
    "golangci-lint-langserver",
    "gopls",
    "gotestsum",
    "graphql-language-service-cli",
    "impl",
    "json-lsp",
    "markdownlint",
    "nil-ls",
    "prettierd",
    "protolint",
    "ruff",
    "rust-analyzer",
    "stylua",
    "superhtml",
    "tailwindcss-language-server",
    "templ",
    "terraform-ls",
    "tflint",
    "tinymist",
    "ts_query_ls",
    "vtsls",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
    "zls",
  })
end

-- refresh() short-circuits on warm cache (24h TTL); install loop runs
-- immediately on cold, after sync refresh on warm.
mason_registry.refresh(function()
  for _, pkg_name in ipairs(ensure_installed) do
    local ok, pkg = pcall(mason_registry.get_package, pkg_name)
    if ok and not pkg:is_installed() then
      pkg:install({}, function(success, err)
        if not success then
          vim.schedule(function()
            vim.notify(("mason: background install of %q failed: %s"):format(pkg_name, err), vim.log.levels.WARN)
          end)
        end
      end)
    end
  end
end)
