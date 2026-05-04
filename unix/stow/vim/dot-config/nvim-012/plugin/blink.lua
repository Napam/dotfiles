if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/Saghen/blink.cmp",            version = vim.version.range("1.*") },
    { src = "https://github.com/rafamadriz/friendly-snippets" },
  })

  local default_sources = { "lsp", "path", "snippets", "buffer", "markdown" }
  local providers = {
    snippets = {
      opts = {
        friendly_snippets = true,
      },
    },
    markdown = {
      name = "RenderMarkdown",
      module = "render-markdown.integ.blink",
    },
  }

  if Config.use_treesitter_parser then
    table.insert(default_sources, "go_pkgs")
    providers.go_pkgs = {
      name = "Import",
      module = "blink-go-import",
    }
  end

  -- Pull in extras published by other plugin/*.lua files at sourcing time
  -- (e.g. lazydev). See README "Cross-plugin sharing via `_G.Config`".
  if Config.blink and Config.blink.extra_providers then
    for name, spec in pairs(Config.blink.extra_providers) do
      providers[name] = spec
    end
  end
  if Config.blink and Config.blink.extra_default_sources then
    for _, src in ipairs(Config.blink.extra_default_sources) do
      if not vim.tbl_contains(default_sources, src) then
        table.insert(default_sources, 1, src)
      end
    end
  end

  require("blink.cmp").setup({
    keymap = {
      ["<C-e>"] = { "hide", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      ["<C-space>"] = { "show" },
    },
    cmdline = {
      enabled = true,
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = true },
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
      },
      keymap = {
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
      },
    },
    completion = {
      trigger = {
        prefetch_on_insert = false,
        show_on_keyword = true,
      },
      list = {
        selection = {
          preselect = false,
          auto_insert = false,
        },
      },
      documentation = { auto_show = true },
      menu = {
        draw = {
          treesitter = { "lsp" },
        },
      },
    },
    signature = { enabled = true },
    appearance = {
      kind_icons = require("icons").kinds,
    },
    sources = {
      default = default_sources,
      providers = providers,
    },
  })
end)
