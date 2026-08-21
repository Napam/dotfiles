-- WARN: source-time load — sibling 0000_priority/ files spawn mason bins.
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

-- HACK: mason-lock notifies "Wrote Mason lockfile" per install (~40x cold). Silence success only.
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

-- setup lives in plugin/lsp.lua: its init() resolves lsp/<name>.lua eagerly, and
-- after/lsp/yamlls.lua needs schemastore — on rtp only after lsp.lua's pack.add.

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

-- WARN: tree-sitter-cli must exist before Config.ts.ensure_parser (0001_nvim-treesitter.lua);
-- first parser compile silently fails otherwise. Cost on first launch only.
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

-- lspconfig server names kept out of derived LSP enablement (plugin/lsp.lua):
-- roslyn is owned by roslyn.nvim (plugin/lang/csharp.lua); stylua/tflint are
-- non-LSPs that still have registry→lspconfig mappings.
Config.mason_lsp_exclude = { "roslyn", "stylua", "tflint" }

-- essentials = pre-built binaries only, so bare machines boot.
-- WARN: stylua needs `unzip` on PATH; kept in extras to avoid breaking essentials.
Config.mason_essential_pkgs = {
  "actionlint",
  "hadolint",
  "lua-language-server",
  "shellcheck",
  "shfmt",
  "taplo",
}
local ensure_installed = Config.mason_essential_pkgs

if not Config.only_essential_plugins() then
  -- Per-ft lazy install; install_pkg skips already-installed pkgs.
  local js_pkgs = { "vtsls", "eslint-lsp", "prettierd" }
  local json_pkgs = { "json-lsp" }
  local terraform_pkgs = { "terraform-ls", "tflint" }
  local bash_pkgs = { "bash-language-server" }

  Config.mason_lazy_by_ft = {
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
    glsl = { "glsl_analyzer" },
    graphql = { "graphql-language-service-cli" },
    html = { "superhtml", "prettierd", "tailwindcss-language-server" },
    css = { "css-lsp", "tailwindcss-language-server", "prettierd" },
    svelte = { "svelte-language-server", "prettierd", "tailwindcss-language-server" },
    typst = { "tinymist" },
    kotlin = { "kotlin-lsp" },
    sql = { "sql-formatter" },
    zig = { "zls" },
    sh = bash_pkgs,
    bash = bash_pkgs,
    bicep = { "bicep-lsp" },
    bicepparam = { "bicep-lsp" },
    templ = { "templ", "rustywind" },
    query = { "ts_query_ls" },
    htmldjango = { "djlint", "jinja-lsp", "rustywind" },
    jinja = { "djlint", "jinja-lsp", "rustywind" },
    powershell = { "powershell-editor-services" },
  }
  local lazy_by_ft = Config.mason_lazy_by_ft

  -- triggered[ft]: install started/done; installing[pkg]: in flight (shared across fts).
  -- KNOWN EDGE: ft B skips a pkg A is mid-installing, so B's ready notify can fire early;
  -- reopening B's file after P lands picks it up.
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
                  -- automatic_enable activates LSP on install success; no reopen.
                  vim.notify(("mason: %s tooling ready"):format(ft))
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
