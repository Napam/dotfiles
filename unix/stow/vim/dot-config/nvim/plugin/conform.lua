if Config.only_essential_plugins() then
  return
end

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/stevearc/conform.nvim" },
  })

  require("conform").setup({
    default_format_opts = {
      lsp_format = "fallback",
    },

    ---@diagnostic disable-next-line: unused-local
    format_on_save = function(bufnr)
      if not vim.g.auto_format then
        return
      end
      return { timeout_ms = 1000 }
    end,

    formatters_by_ft = {
      dependabot = { "prettierd" },
      gha = { "prettierd" },
      go = { "golangci-lint" },
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      json = { "biome" },
      -- FIXME: biome supports JSON/JSONC but not JSON5 (single-quoted strings,
      -- unquoted keys, etc.). Pick a real json5 formatter or drop the entry.
      -- json5 = { "biome" },
      jsonc = { "biome" },
      lua = { "stylua" },
      markdown = { "prettierd" },
      nix = { "nixfmt" },
      proto = { "buf" },
      sh = { "shfmt" },
      sql = { "sql_formatter" },
      terraform = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
      tf = { "terraform_fmt" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      yaml = { "prettierd" },
    },

    formatters = {
      -- WARN: full args override (not prepend_args). Built-in is { "fmt", "--stdin" };
      -- $FILENAME is required so golangci-lint resolves the module/config and picks
      -- the right sub-formatters (gofmt, gci, etc.) for the file's path.
      ["golangci-lint"] = {
        args = { "fmt", "--stdin", "$FILENAME" },
      },
      biome = {
        args = { "format", "--indent-style", "space", "--stdin-file-path", "$FILENAME" },
      },
      {
        command = "sql-formatter",
        cwd = require("conform.util").root_file({
          ".sql-formatter.json",
        }),
      },
    },
  })

  vim.keymap.set("n", "<leader>lf", function()
    require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
  end, { desc = "Format" })
end)
