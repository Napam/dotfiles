-- Source-time load (not on_vim_enter): mason bin on PATH before sibling
-- 0000_priority/ files spawn binaries. See README "0000_priority/ load order".
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/zapling/mason-lock.nvim" },
})

-- prepend: mason bins shadow system bins (e.g. stale system tree-sitter).
require("mason").setup({ PATH = "prepend" })

require("mason-lock").setup({})

require("mason-lspconfig").setup({
  automatic_enable = false,   -- we handle vim.lsp.enable() ourselves
})

local mason_registry = require("mason-registry")

-- Tools needed early enough that we can't tolerate the background-install
-- delay. Installed synchronously (blocks UI on first install only; subsequent
-- runs short-circuit at pkg:is_installed). Add here only if a sourcing-time
-- consumer can't tolerate absence. Most tools belong in `ensure_installed`.
--
-- tree-sitter-cli rationale: nvim-treesitter's `ensure_parser` runs from a
-- FileType handler and *does* tolerate a missing CLI (logs a friendly warning
-- and returns false). We still install it sync so the very first file opened
-- in a fresh install gets working highlighting without requiring a second
-- file-open after the background install completes. The trade-off (15s
-- registry refresh + up to 60s npm install on first launch only) is
-- considered acceptable here; revisit if it becomes painful.
local critical_sync = { "tree-sitter-cli" }

do
  local refreshed = false
  mason_registry.refresh(function() refreshed = true end)
  if not vim.wait(15000, function() return refreshed end, 50) then
    vim.notify("mason: registry refresh timed out (15s)", vim.log.levels.WARN)
  end

  for _, name in ipairs(critical_sync) do
    local ok, pkg = pcall(mason_registry.get_package, name)
    if ok and not pkg:is_installed() then
      local done = false
      pkg:install({}, function(success, err)
        done = true
        if not success then
          vim.notify(
            ("mason: failed to install critical tool %q: %s"):format(name, err),
            vim.log.levels.ERROR
          )
        end
      end)
      -- 60s/tool. tree-sitter-cli is npm (~5-15s typical).
      if not vim.wait(60000, function() return done end, 100) then
        vim.notify(
          ("mason: install of %q timed out (60s); continuing"):format(name),
          vim.log.levels.ERROR
        )
      end
      -- Failure already notified; ensure_parser surfaces missing tool at use time.
    end
  end

  -- Belt-and-suspenders: re-prepend mason bin in case setup() ran pre-install.
  -- Use component-wise comparison to avoid substring false-positives (e.g. a
  -- pre-existing `/foo/mason/bin/extra` would otherwise mask the real entry).
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  local path_parts = vim.split(vim.env.PATH or "", ":", { plain = true })
  if not vim.tbl_contains(path_parts, mason_bin) then
    vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
  end
end

-- Non-critical background install: fire-and-forget. Available some time after
-- VimEnter; consumers must tolerate that.
--
-- Profile-aware: the essentials list contains only mason packages distributed
-- as pre-built binaries (verified via mason-registry `pkg:github/...` source
-- IDs) so they install on a fresh machine with no language toolchains.
local ensure_installed
if Config.only_essential_plugins() then
  ensure_installed = {
    "tree-sitter-cli",          -- pre-built binary; needed by ensure_parser
    "lua-language-server",      -- pre-built binary; lua_ls works without external toolchain
    "stylua",                   -- pre-built binary
    "shellcheck",               -- pre-built binary
    "shfmt",                    -- pre-built binary
    "taplo",                    -- pre-built binary
    "hadolint",                 -- pre-built binary
    "actionlint",               -- pre-built binary
  }
else
  ensure_installed = {
    "actionlint",
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
    "gci",
    "gofumpt",
    "goimports",
    "golangci-lint",
    "golines",
    "gopls",
    "gotestsum",
    "graphql-language-service-cli",
    "hadolint",
    "impl",   -- used by go-impl.nvim
    "json-lsp",
    "lua-language-server",
    "markdownlint",
    "nil-ls",
    "prettier",
    "protolint",
    "ruff",
    "rust-analyzer",
    "shellcheck",
    "shfmt",
    "stylua",
    "superhtml",
    "tailwindcss-language-server",
    "taplo",
    "templ",
    "terraform-ls",
    "tflint",
    "tinymist",
    -- NOTE: tree-sitter-cli handled in `critical_sync` above.
    "ts_query_ls",
    "vtsls",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
    "zls",
  }
end

-- Background install. refresh() short-circuits on fresh in-memory cache
-- (24h TTL), so this runs the install loop immediately.
mason_registry.refresh(function()
  for _, pkg_name in ipairs(ensure_installed) do
    local ok, pkg = pcall(mason_registry.get_package, pkg_name)
    if ok and not pkg:is_installed() then
      pkg:install({}, function(success, err)
        if not success then
          vim.schedule(function()
            vim.notify(
              ("mason: background install of %q failed: %s"):format(pkg_name, err),
              vim.log.levels.WARN
            )
          end)
        end
      end)
    end
  end
end)
