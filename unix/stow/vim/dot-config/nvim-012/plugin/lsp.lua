require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/artemave/workspace-diagnostics.nvim" },
  })

  -- Extend LSP capabilities with blink.cmp completions for all servers.
  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
  })

  -- Per-server configuration overrides.
  -- These must run BEFORE vim.lsp.enable() so the merged config is used at attach.
  -- vim.lsp.config(name, cfg) deep-merges with any prior call (and lspconfig defaults).

  vim.lsp.config("basedpyright", {
    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = "standard",
          diagnosticSeverityOverrides = {
            reportImplicitStringConcatenation = false,
            -- Let the linter (ruff) report unused; avoid duplicate diagnostics.
            reportUnusedImport = false,
            reportUnusedVariable = false,
          },
        },
      },
    },
  })

  vim.lsp.config("eslint", {
    settings = { format = false },
  })

  vim.lsp.config("gopls", {
    settings = {
      gopls = {
        hints = {
          -- assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  })

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        hint = {
          enable = true,
          ---@type "Auto" | "Enable" | "Disable"
          arrayIndex = "Disable",
          ---@type "All" | "Literal" | "Disable"
          paramName = "Literal",
          setType = true,
        },
      },
    },
    ---@param client vim.lsp.Client
    on_init = function(client)
      local ok, workspace_folder = pcall(unpack, client.workspace_folders)
      if not ok then
        return
      end
      local path = workspace_folder.name
      if
          vim.uv.fs_stat(path .. "/.luarc.json")
          or vim.uv.fs_stat(path .. "/.luarc.jsonc")
      then
        return
      end

      client.config.settings.Lua =
      ---@diagnostic disable-next-line: param-type-mismatch
          vim.tbl_deep_extend("force", client.config.settings.Lua, {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = "Disable",
              library = {
                "${3rd}/luv/library",
                unpack(vim.api.nvim_get_runtime_file("", true)),
              },
            },
          })
    end,
    on_attach = function()
      -- HACK: https://github.com/LuaLS/lua-language-server/issues/1809
      vim.api.nvim_set_hl(0, "@lsp.type.comment", {})
    end,
  })

  vim.lsp.config("ruff", {
    settings = {},
  })

  -- vtsls (modern ts_ls successor). Inlay hints schema differs from ts_ls.
  vim.lsp.config("vtsls", {
    settings = {
      typescript = {
        inlayHints = {
          enumMemberValues = { enabled = true },
          parameterNames = { enabled = "all" },
        },
      },
      javascript = {
        inlayHints = {
          enumMemberValues = { enabled = true },
          parameterNames = { enabled = "all" },
        },
      },
    },
  })

  vim.lsp.config("tailwindcss", {
    settings = {
      tailwindCSS = {
        experimental = {
          classRegex = {
            "\\w+Class=\\{?['\"]([^'\"]*)\\}?",
            "(?:\\b(?:const|let|var)\\s+)?[\\w$_]*(?:[Ss]tyles|[Cc]lasses|[Cc]lassnames|[Cc]lass)[\\w\\d]*\\s*(?:=|\\+=)\\s*['\"`]([^'\"`]*)['\"`]",
            { "(?:twMerge|twJoin|Merge|[Aa]dd)\\(([^;]*)[\\);]", "[`'\"`]([^'\"`;]*)[`'\"`]" },
            {
              "(tw`(?:(?:(?:[^`]*\\$\\{[^]*?\\})[^`]*)+|[^`]*`))",
              "((?:(?<=`)(?:[^\"'`]*)(?=\\${|`))|(?:(?<=\\})(?:[^\"'`]*)(?=\\${))|(?:(?<=\\})(?:[^\"'`]*)(?=`))|(?:(?<=')(?:[^\"'`]*)(?='))|(?:(?<=\")(?:[^\"'`]*)(?=\"))|(?:(?<=`)(?:[^\"'`]*)(?=`)))",
            },
          },
        },
      },
    },
  })

  vim.lsp.config("yamlls", {
    settings = {
      keyOrdering = false,
    },
  })

  vim.lsp.config("tinymist", {
    root_markers = { "typst.toml", ".git" },
    settings = {
      formatterMode = "typstyle",
      formatterProseWrap = true,
      fontPaths = { "fonts" },
    },
  })

  vim.lsp.config("codebook", {
    cmd = function(dispatchers, config)
      local root = config.root_dir or vim.uv.cwd()
      return vim.lsp.rpc.start({ "codebook-lsp", "-r", root, "serve" }, dispatchers)
    end,
    filetypes = {
      "c", "css", "gitcommit", "go", "haskell", "html", "java",
      "javascript", "javascriptreact", "lua", "markdown", "php",
      "python", "ruby", "rust", "swift", "toml", "text",
      "typescript", "typescriptreact", "typst", "zig",
    },
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, { "codebook.toml", ".codebook.toml" })
      if root then
        on_dir(root)
      end
    end,
  })

  vim.lsp.config("denols", {
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
      if root then
        on_dir(root)
      end
    end,
  })

  vim.lsp.config("golangci_lint_ls", {
    cmd = { "golangci-lint-langserver" },
    filetypes = { "go", "gomod" },
    init_options = {
      command = { "golangci-lint", "run", "--output.json.path=stdout", "--show-stats=false" },
    },
    root_markers = {
      ".golangci.yml",
      ".golangci.yaml",
      ".golangci.toml",
      ".golangci.json",
      "go.mod",
      ".git",
    },
    before_init = function(_, config)
      -- Add support for golangci-lint V1 (in V2 `--out-format=json` was replaced by
      -- `--output.json.path=stdout`).
      local v1, v2 = false, false
      -- PERF: `golangci-lint version` is very slow (~0.1s); detect version via
      -- `go version -m $(which golangci-lint)` instead.
      if vim.fn.executable("go") == 1 then
        local exe = vim.fn.exepath("golangci-lint")
        local version = vim.system({ "go", "version", "-m", exe }):wait()
        v1 = string.match(version.stdout, "\tmod\tgithub.com/golangci/golangci%-lint\t")
        v2 = string.match(version.stdout, "\tmod\tgithub.com/golangci/golangci%-lint/v2\t")
      end
      if not v1 and not v2 then
        local version = vim.system({ "golangci-lint", "version" }):wait()
        v1 = string.match(version.stdout, "version v?1%.")
      end
      if v1 then
        config.init_options.command = { "golangci-lint", "run", "--out-format", "json" }
      end
    end,
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
    "jsonls",
    "lua_ls",
    "nil_ls",
    "ruff",
    "rust_analyzer",
    "superhtml",
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

  -- Enable codelens globally
  vim.lsp.codelens.enable(true)

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buf = args.buf

      if client then
        -- Disable codelens for lua (lua_ls "0 References" is noisy)
        if client.name == "lua_ls" then
          vim.lsp.codelens.enable(false, { bufnr = buf })
        end

        -- LSP folding (override treesitter default from init.lua)
        if client:supports_method("textDocument/foldingRange", buf) then
          require("fold").lsp_foldexpr(vim.api.nvim_get_current_win())
        end

        -- Workspace diagnostics
        if client:supports_method("workspace/diagnostic", buf) then
          vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
        else
          require("workspace-diagnostics").populate_workspace_diagnostics(client, buf)
        end

        -- Inline completion
        if client:supports_method("textDocument/inlineCompletion", buf) then
          vim.lsp.inline_completion.enable(true)
        end

        -- Linked editing (e.g., paired HTML tags)
        if client:supports_method("textDocument/linkedEditingRange", buf) then
          vim.lsp.linked_editing_range.enable(true, { bufnr = buf })
        end

        -- Inline color swatches
        if client:supports_method("textDocument/documentColor", buf) then
          vim.lsp.document_color.enable(true, { bufnr = buf })
        end

        -- Format on typing trigger characters
        -- NOTE: I think I rather use conform.nvim as otherwise this yields unexpected results.
        -- if client:supports_method("textDocument/onTypeFormatting", buf) then
        --   vim.lsp.on_type_formatting.enable(true, { bufnr = buf })
        -- end
      end

      -- Keymaps
      -- LSP keymaps not covered by snacks picker (gd, gD, gr, gI, gt are in snacks.lua)
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

  -- Reset diagnostics on detach so :lsp restart/:lsp stop don't leave stale state.
  vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("lsp-detach-cleanup", { clear = true }),
    callback = function(args)
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

  -- LSP progress spinner
  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup("lsp-progress", { clear = true }),
    ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
    callback = function(ev)
      local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
      vim.notify(vim.lsp.status(), vim.log.levels.INFO, {
        id = "lsp_progress",
        title = "LSP Progress",
        opts = function(notif)
          notif.icon = ev.data.params.value.kind == "end" and " "
              or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
        end,
      })
    end,
  })
end)
