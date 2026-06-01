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

  local servers = {
    "basedpyright",
    "bashls",
    "buf_ls",
    "codebook",
    "denols",
    "dockerls",
    "eslint",
    "golangci_lint_ls",
    "gopls",
    "graphql",
    "jinja_lsp",
    "jsonls",
    "kotlin_lsp",
    "lua_ls",
    "nil_ls",
    "ruff",
    "rust_analyzer",
    "superhtml",
    "svelte",
    "tailwindcss",
    "templ",
    "terraformls",
    "tinymist",
    "ts_query_ls",
    "vtsls",
    "yamlls",
    "zls",
  }
  vim.lsp.enable(servers)

  vim.filetype.add({
    extension = {
      jinja = "htmldjango",
      jinja2 = "htmldjango",
      j2 = "htmldjango",
    },
  })

  -- Codelens opt-in per-buffer; enable globally so attached clients render it.
  vim.lsp.codelens.enable(true)

  -- WARN: per-client guard. workspace_diagnostics is workspace-scoped; LspAttach
  -- fires per (client, buf), so without this every buffer re-scans.
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

        -- Workspace diagnostics: pull (LSP 3.17) if supported, else simulate
        -- via workspace-diagnostics.nvim (sends didOpen for every file — slow).
        if not ws_diag_done[client.id] then
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
      -- WARN: clear ws_diag_done BEFORE the get_client_by_id guard, else
      -- early-return on a gone client leaks the entry.
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
