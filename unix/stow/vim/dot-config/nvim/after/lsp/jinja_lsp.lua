---@brief
---
--- jinja-lsp enhances minijinja development experience by providing Helix/Nvim users with advanced features such as autocomplete, syntax highlighting, hover, goto definition, code actions and linting.
---
--- The file types are not detected automatically, you can register them manually (see below) or override the filetypes:
---
--- ```lua
--- vim.filetype.add {
---   extension = {
---     jinja = 'jinja',
---     jinja2 = 'jinja',
---     j2 = 'jinja',
---   },
--- }
--- ```
---@type vim.lsp.Config
return {
  name = "jinja_lsp",
  cmd = { "jinja-lsp" },
  filetypes = { "jinja", "rust", "python", "htmldjango" },
  -- jinja-lsp resolves {% extends %}/{% include %} against this directory and
  -- indexes backend context variables from src/. Paths are relative to cwd,
  -- which Neovim sets to root_dir.
  init_options = {
    templates = "./templates",
    backend = { "./src" },
    lang = "rust",
  },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { "jinja-lsp.toml", "pyproject.toml", ".git" })
    if root then
      on_dir(root)
    end
  end,
  handlers = {
    ["textDocument/publishDiagnostics"] = function(_, result, ctx)
      -- jinja-lsp only learns context variables from minijinja's context!{}
      -- macro. Templates rendered from #[derive(Serialize)] structs then report
      -- their top-level variables as "Undefined variable". tests/render.rs
      -- renders every template under Strict undefined behavior, so drop that
      -- warning class and keep the rest.
      if result and result.diagnostics then
        result.diagnostics = vim.tbl_filter(function(d)
          return not d.message:match("Undefined variable")
        end, result.diagnostics)
      end
      vim.lsp.handlers["textDocument/publishDiagnostics"](_, result, ctx)
    end,
  },
}
