-- WARN: source-time load — mason bin must be on PATH before sibling
-- 0000_priority/ files spawn binaries.
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/zapling/mason-lock.nvim" },
})

-- WARN: prepend so mason bins shadow stale system bins (e.g. system tree-sitter).
require("mason").setup({ PATH = "prepend" })
require("mason-lock").setup({})

-- HACK: mason-lock notifies "Wrote Mason lockfile" on every package install
-- success (~40x on cold install). Silence the success notify; keep errors.
do
  local ml = require("mason-lock")
  local orig = ml.write_lockfile
  ---@diagnostic disable-next-line: duplicate-set-field
  ml.write_lockfile = function(...)
    local notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, level, opts)
      if type(msg) == "string" and msg:find("Wrote Mason lockfile", 1, true) then
        return
      end
      return notify(msg, level, opts)
    end
    local ok, err = pcall(orig, ...)
    vim.notify = notify
    if not ok then
      error(err)
    end
  end
end

-- automatic_enable=false: vim.lsp.enable() handled in plugin/lsp.lua. Kept for
-- mason<->lspconfig name aliases (e.g. lua_ls -> lua-language-server).
require("mason-lspconfig").setup({ automatic_enable = false })

local mason_registry = require("mason-registry")

local function install_pkg(name, on_done)
  local ok, pkg = pcall(mason_registry.get_package, name)
  if not ok then
    if on_done then
      on_done(false, "package not found")
    end
    return
  end
  if pkg:is_installed() then
    if on_done then
      on_done(true)
    end
    return
  end
  pkg:install({}, function(success, err)
    if on_done then
      on_done(success, err)
    end
  end)
end

-- WARN: tree-sitter-cli must exist before Config.ts.ensure_parser
-- (0001_nvim-treesitter.lua); first parser compile silently fails otherwise.
-- Cost: ~15s refresh + ~5-15s install on FIRST launch only.
local critical_sync = { "tree-sitter-cli" }

-- PERF: file-on-disk sentinel skips the sync block (~13ms) on warm cache.
local ts_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "tree-sitter")
if vim.uv.fs_stat(ts_bin) == nil then
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
    local done = false
    install_pkg(name, function(success, err)
      done = true
      if not success then
        vim.notify(("mason: failed to install %q: %s"):format(name, err or "unknown error"), vim.log.levels.ERROR)
      end
    end)
    if not vim.wait(60000, function()
      return done
    end, 100) then
      vim.notify(("mason: install of %q timed out (60s); continuing"):format(name), vim.log.levels.ERROR)
    end
  end
end

-- essentials = pre-built binaries only, so bare machines boot.
-- WARN: stylua needs `unzip` on PATH; kept in extras to avoid breaking essentials.
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
    "prettierd",
    "protolint",
    "ruff",
    "rust-analyzer",
    "stylua",
    "sql-formatter",
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

-- refresh() short-circuits on warm cache (24h TTL).
mason_registry.refresh(function()
  for _, pkg_name in ipairs(ensure_installed) do
    install_pkg(pkg_name, function(success, err)
      if not success then
        vim.schedule(function()
          vim.notify(
            ("mason: background install of %q failed: %s"):format(pkg_name, err or "unknown error"),
            vim.log.levels.WARN
          )
        end)
      end
    end)
  end
end)
