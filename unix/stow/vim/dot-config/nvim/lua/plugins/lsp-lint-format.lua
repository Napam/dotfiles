return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local lspconfig = require("lspconfig")

      require("mason-lspconfig").setup_handlers({
        -- Mason language servers with default setups
        function(server_name)
          lspconfig[server_name].setup({})
        end,

        -- Mason language servers with custom setups
        basedpyright = function()
          lspconfig["basedpyright"].setup({
            settings = {
              basedpyright = {
                analysis = {
                  typeCheckingMode = "standard",
                  diagnosticSeverityOverrides = {
                    reportImplicitStringConcatenation = false,
                    -- Let linter handle unused stuff, or will have double up with essentially same message
                    reportUnusedImport = false,
                    reportUnusedVariable = false,
                  },
                },
              },
            },
          })
        end,

        eslint = function()
          lspconfig["eslint"].setup({
            settings = { format = false },
          })
        end,

        gopls = function()
          lspconfig["gopls"].setup({
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
        end,

        lua_ls = function()
          lspconfig["lua_ls"].setup({
            settings = {
              Lua = {
                hint = {
                  enable = true,
                  ---@type "Auto" | "Enable" | "Disable"
                  arrayIndex = "Disable",
                  -- await = true,
                  -- awaitPropagate = false,
                  ---@type "All" | "Literal" | "Disable"
                  paramName = "Literal",
                  -- paramType = true,
                  -- ---@type "All" | "SameLine" | "Disable"
                  -- semicolon = "SameLine",
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
        end,

        ruff = function()
          lspconfig["ruff"].setup({
            ---@param client vim.lsp.Client
            on_attach = function(client)
              client.server_capabilities.hoverProvider = false
            end,
          })
        end,

        ts_ls = function()
          lspconfig["ts_ls"].setup({
            root_dir = function(file)
              return vim.fs.root(file, { "package.json", "tsconfig.json", "jsconfig.json" })
            end,
            single_file_support = false,
            init_options = {
              preferences = {
                includeInlayEnumMemberValueHints = true,
                -- includeInlayFunctionLikeReturnTypeHints = false,
                -- includeInlayFunctionParameterTypeHints = false,
                includeInlayParameterNameHints = "all",
                -- includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                -- includeInlayPropertyDeclarationTypeHints = true,
                -- includeInlayVariableTypeHints = false,
                -- includeInlayVariableTypeHintsWhenTypeMatchesName = false,
              },
            },
            ---@param client vim.lsp.Client
            on_attach = function(client)
              client.server_capabilities.documentFormattingProvider = false
            end,
          })
        end,

        tailwindcss = function()
          lspconfig["tailwindcss"].setup({
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
        end,

        yamlls = function()
          lspconfig["yamlls"].setup({
            settings = {
              yaml = { keyOrdering = false },
            },
          })
        end,

        denols = function()
          lspconfig["denols"].setup({
            root_dir = function(file)
              return vim.fs.root(file, { "deno.json", "deno.jsonc" })
            end,
          })
        end,
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
        "bashls",
        "denols",
        "eslint",
        "goimports",
        "gopls",
        "graphql",
        "html",
        "jsonls",
        "lua_ls",
        "ruff",
        "rust_analyzer",
        "rustywind",
        "svelte",
        "tailwindcss",
        "templ",
        "ts_ls",
        "yamlls",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      local conform = require("conform")
      conform.setup({
        formatters_by_ft = {
          sh = { "shfmt" },
          zsh = { "shfmt" },
          lua = { "stylua" },
          sql = { "sql_formatter" },
          bash = { "shfmt" },
          python = { "ruff_format", "ruff_organize_imports" },
          markdown = { "prettierd" },
          javascript = { "prettierd", "rustywind" },
          typescript = { "prettierd" },
          typescriptreact = { "prettierd" },
          javascriptreact = { "prettierd" },
          graphql = { "prettierd" },
          go = { "goimports", lsp_format = "last" },
          templ = { "templ", "html", "rustywind", "goimports" },
          typst = { "typstyle" },
        },
      })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    dependencies = {
      {
        "rafamadriz/friendly-snippets",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
          })
        end,
      },
    },
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
  },
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },

    -- use a release tag to download pre-built binaries
    version = "1.*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    build = "cargo build --release",
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = {
        preset = "enter",
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = {
        documentation = {
          auto_show = false
        }
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
