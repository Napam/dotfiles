if Config.only_essential_plugins() then
  return
end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/artemave/workspace-diagnostics.nvim" },
    { src = "https://github.com/b0o/SchemaStore.nvim" },
  })

  -- WARN: must run BEFORE vim.lsp.enable() so merged config is used at attach.
  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
  })

  -- HACK: workspace-diagnostics.nvim's populate_workspace_diagnostics() raw-notifies
  -- textDocument/didOpen for every workspace file on attach (our fallback for clients
  -- lacking workspace/diagnostic at attach time — roslyn registers pull diagnostics
  -- only after attach). The server then holds those docs open, but nvim tracks nothing,
  -- so opening the file for real (e.g. gd) sends a second didOpen with no didClose and
  -- roslyn-language-server Contract.Fails (process death). Server-side, arguably bad
  -- behavior; client-side we just dedup. Upstream nvim fix closed unmerged:
  -- https://github.com/neovim/neovim/pull/38301
  -- Guard at notify level so raw plugin notifies and core sends share one dedup set;
  -- a handler-level guard misses the plugin's bypass.
  -- WARN: patches ALL clients; must run before any client attaches (sits above
  -- mason-lspconfig.setup for that reason). Remove once nvim guards didOpen itself.
  local Client = require("vim.lsp.client")
  local orig_notify = Client.notify
  ---@diagnostic disable-next-line: duplicate-set-field
  function Client:notify(method, params, ...)
    if method == "textDocument/didOpen" then
      local uri = params and params.textDocument and params.textDocument.uri
      self._didopen_uris = self._didopen_uris or {}
      if uri then
        if self._didopen_uris[uri] then
          return false
        end
        local sent = orig_notify(self, method, params, ...)
        -- WARN: unmark on failed send so a later legit attempt isn't swallowed.
        if not sent then
          self._didopen_uris[uri] = nil
        end
        return sent
      end
    elseif method == "textDocument/didClose" then
      local uri = params and params.textDocument and params.textDocument.uri
      if uri and self._didopen_uris then
        self._didopen_uris[uri] = nil
      end
    end
    return orig_notify(self, method, params, ...)
  end

  -- LSP allowlist derived from 0004_mason.lua's install lists — single source of truth.
  -- Exclusions live in Config.mason_lsp_exclude (server names, next to the data they guard).
  -- Allowlist form: bare `true` enables every installed pkg with a registry mapping,
  -- listed or not; a table WITH an `exclude` key flips to exclude-list semantics.
  -- WARN: must stay after the pack.add above — init() resolves lsp/<name>.lua
  -- immediately, and after/lsp/yamlls.lua requires schemastore from SchemaStore.nvim.
  local excluded_servers = {}
  for _, name in ipairs(Config.mason_lsp_exclude) do
    excluded_servers[name] = true
  end
  local lsp_name_of = require("mason-lspconfig").get_mappings().package_to_lspconfig
  local seen, servers = {}, {}
  local function add_pkg(pkg)
    local name = lsp_name_of[pkg]
    if name and not excluded_servers[name] and not seen[name] then
      seen[name] = true
      servers[#servers + 1] = name
    end
  end
  for _, pkg in ipairs(Config.mason_essential_pkgs) do
    add_pkg(pkg)
  end
  for _, pkgs in pairs(Config.mason_lazy_by_ft) do
    for _, pkg in ipairs(pkgs) do
      add_pkg(pkg)
    end
  end
  table.sort(servers)
  if #servers == 0 then
    vim.notify(
      "lsp.lua: derived empty server list (mason registry cache missing?) — no LSPs enabled",
      vim.log.levels.WARN
    )
  end
  require("mason-lspconfig").setup({ automatic_enable = servers })

  vim.filetype.add({
    extension = {
      jinja = "htmldjango",
      jinja2 = "htmldjango",
      j2 = "htmldjango",
    },
  })

  -- Codelens opt-in per-buffer; enable globally so attached clients render it.
  vim.lsp.codelens.enable(true)

  -- WARN: per-client guard — LspAttach fires per (client, buf); without this every buffer re-scans.
  local ws_diag_done = {} ---@type table<integer, boolean>

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buf = args.buf

      if client then
        if client:supports_method("textDocument/foldingRange", buf) then
          -- WARN: async attach — buf may be in 0+ windows, none current.
          for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            require("fold").lsp_foldexpr(win)
          end
        end

        -- Native pull (LSP 3.17) if supported, else simulate via didOpen-per-file (slow).
        -- WARN: basedpyright scans natively; simulated didOpen for open bufs makes it complain.
        local ws_diag_native = { basedpyright = true, pyright = true }
        if not ws_diag_done[client.id] and not ws_diag_native[client.name] then
          ws_diag_done[client.id] = true
          if client:supports_method("workspace/diagnostic", buf) then
            vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
          else
            require("workspace-diagnostics").populate_workspace_diagnostics(client, buf)
          end
        end

        if client:supports_method("textDocument/inlineCompletion", buf) then
          vim.lsp.inline_completion.enable(true, { bufnr = buf })
        end

        if client:supports_method("textDocument/linkedEditingRange", buf) then
          vim.lsp.linked_editing_range.enable(true, { bufnr = buf })
        end

        if client:supports_method("textDocument/documentColor", buf) then
          vim.lsp.document_color.enable(true, { bufnr = buf })
        end
      end

      -- Keymaps once per buf (LspAttach fires per client). gd/gD/gr/gI/gy in whichkey.lua.
      if vim.b[buf].lsp_keymaps_set then
        return
      end
      vim.b[buf].lsp_keymaps_set = true

      vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "Hover" })
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "Code action" })
      vim.keymap.set("n", "<leader>cc", vim.lsp.codelens.run, { buffer = buf, desc = "Run codelens" })
      vim.keymap.set({ "n", "x" }, "<M-o>", function()
        vim.lsp.buf.selection_range(1)
      end, { buffer = buf, desc = "Expand selection (LSP)" })
      vim.keymap.set("x", "<M-i>", function()
        vim.lsp.buf.selection_range(-1)
      end, { buffer = buf, desc = "Shrink selection (LSP)" })
      vim.keymap.set("n", "<leader>uh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
      end, { buffer = buf, desc = "Toggle inlay hints" })
      vim.keymap.set("n", "<leader>ul", function()
        local enabled = not vim.lsp.codelens.is_enabled()
        vim.lsp.codelens.enable(enabled)
        vim.notify("Codelens: " .. (enabled and "on" or "off"))
      end, { buffer = buf, desc = "Toggle codelens" })
      vim.keymap.set("n", "[d", function()
        vim.diagnostic.jump({ count = -1 })
      end, { buffer = buf, desc = "Prev diagnostic" })
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.jump({ count = 1 })
      end, { buffer = buf, desc = "Next diagnostic" })
    end,
  })

  -- Reset diagnostics on detach so :lsp restart/stop don't leave stale state.
  vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("lsp-detach-cleanup", { clear = true }),
    callback = function(args)
      -- WARN: clear before the client guard — early-return on a gone client would leak the entry.
      ws_diag_done[args.data.client_id] = nil

      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      local prefix = ("nvim.lsp.%s.%d"):format(client.name, client.id)
      for namespace, metadata in pairs(vim.diagnostic.get_namespaces()) do
        local name = metadata.name or ""
        if name == prefix or vim.startswith(name, prefix .. ".") then
          vim.diagnostic.reset(namespace)
        end
      end
    end,
  })
end)
