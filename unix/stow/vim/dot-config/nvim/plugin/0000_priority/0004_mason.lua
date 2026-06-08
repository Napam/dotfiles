-- WARN: source-time load — mason bin must be on PATH before sibling
-- 0000_priority/ files spawn binaries.
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/zapling/mason-lock.nvim" },
})

-- WARN: prepend so mason bins shadow stale system bins (e.g. system tree-sitter).
require("mason").setup({
  PATH = "prepend",
  registries = {
    "github:Crashdummyy/mason-registry",
    "github:mason-org/mason-registry",
  },
})
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
  -- Install tools lazily on first encounter of a filetype rather than all at
  -- once on startup. install_pkg is idempotent; already-installed packages are
  -- skipped immediately.
  local js_pkgs = { "vtsls", "eslint-lsp", "prettierd" }
  local json_pkgs = { "json-lsp" }
  local terraform_pkgs = { "terraform-ls", "tflint" }
  local bash_pkgs = { "bash-language-server" }

  local lazy_by_ft = {
    python = { "basedpyright", "ruff", "debugpy" },
    go = { "gopls", "golangci-lint", "golangci-lint-langserver", "delve", "gotestsum", "impl" },
    javascript = js_pkgs,
    typescript = js_pkgs,
    javascriptreact = js_pkgs,
    typescriptreact = js_pkgs,
    rust = { "rust-analyzer", "codelldb" },
    cs = { "roslyn", "csharpier", "netcoredbg" },
    lua = { "stylua" },
    markdown = { "prettierd", "markdownlint", "codebook" },
    json = json_pkgs,
    jsonc = json_pkgs,
    yaml = { "yaml-language-server", "prettierd", "yamlfmt", "yamllint" },
    terraform = terraform_pkgs,
    ["terraform-vars"] = terraform_pkgs,
    dockerfile = { "dockerfile-language-server" },
    proto = { "buf", "api-linter", "protolint" },
    graphql = { "graphql-language-service-cli" },
    html = { "superhtml", "prettierd", "tailwindcss-language-server" },
    css = { "tailwindcss-language-server", "prettierd" },
    svelte = { "prettierd", "tailwindcss-language-server" },
    typst = { "tinymist" },
    kotlin = { "kotlin-lsp" },
    sql = { "sql-formatter" },
    zig = { "zls" },
    sh = bash_pkgs,
    bash = bash_pkgs,
    templ = { "templ" },
    query = { "ts_query_ls" },
  }

  -- triggered[ft]: true = install in progress or done; nil = not yet started.
  -- installing[pkg]: true = install in flight (may be shared across filetypes).
  -- KNOWN EDGE: if ft A starts installing pkg P, and ft B then triggers with P
  -- in its list, B skips P from its pending counter. B's "ready" notify may fire
  -- before P actually finishes. Reopening B's file after P lands picks it up.
  local triggered = {}
  local installing = {}

  vim.api.nvim_create_user_command("MasonEagerInstallAll", function()
    local seen = {}
    local all_pkgs = {}
    for _, pkgs in pairs(lazy_by_ft) do
      for _, pkg_name in ipairs(pkgs) do
        if not seen[pkg_name] then
          seen[pkg_name] = true
          table.insert(all_pkgs, pkg_name)
        end
      end
    end
    vim.notify(("mason: eager-installing %d packages…"):format(#all_pkgs), vim.log.levels.INFO)
    mason_registry.refresh(function()
      for _, pkg_name in ipairs(all_pkgs) do
        install_pkg(pkg_name, function(success, err)
          if not success then
            vim.schedule(function()
              vim.notify(
                ("mason: eager install of %q failed: %s"):format(pkg_name, err or "unknown"),
                vim.log.levels.WARN
              )
            end)
          end
        end)
      end
    end)
  end, { desc = "Install all lazy_by_ft mason packages" })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("mason-lazy-install", { clear = true }),
    callback = function(event)
      local ft = event.match
      if triggered[ft] then
        return
      end
      local pkgs = lazy_by_ft[ft]
      if not pkgs then
        return
      end
      triggered[ft] = true

      mason_registry.refresh(function()
        local to_install = {}
        for _, pkg_name in ipairs(pkgs) do
          local ok, pkg = pcall(mason_registry.get_package, pkg_name)
          if not ok then
            vim.notify(
              ("mason: unknown package %q in lazy_by_ft[%s] — typo?"):format(pkg_name, ft),
              vim.log.levels.WARN
            )
          elseif not pkg:is_installed() and not installing[pkg_name] then
            table.insert(to_install, { name = pkg_name, pkg = pkg })
          end
        end
        if #to_install == 0 then
          return
        end

        local pending = #to_install
        local had_failure = false
        for _, item in ipairs(to_install) do
          installing[item.name] = true
          vim.notify(("mason: installing %q"):format(item.name), vim.log.levels.INFO)
          item.pkg:install({}, function(success, err)
            vim.schedule(function()
              installing[item.name] = nil
              if success then
                vim.notify(("mason: installed %q"):format(item.name))
              else
                had_failure = true
                vim.notify(("mason: failed to install %q: %s"):format(item.name, err or "unknown"), vim.log.levels.WARN)
              end
              pending = pending - 1
              if pending == 0 then
                if had_failure then
                  triggered[ft] = nil
                  vim.notify(("mason: some %s tools failed — reopen file to retry"):format(ft), vim.log.levels.WARN)
                else
                  vim.notify(("mason: %s tooling ready — reopen file to activate LSP"):format(ft))
                end
              end
            end)
          end)
        end
      end)
    end,
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
