-- Filetype detection tweaks. Must run at startup (NOT lazyload.on_vim_enter):
-- the startup buffer's filetype is detected before VimEnter, so registering
-- these lazily misses `nvim foo.gotmpl` / `nvim empty.tf` given as argv.
vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
    jinja = "htmldjango",
    jinja2 = "htmldjango",
    j2 = "htmldjango",
    -- Upstream *.tf detection sniffs content and falls back to ft=tf (the
    -- TinyFugue MUD client) for files without terraform-looking lines, e.g. a
    -- freshly created empty main.tf. Always terraform here.
    tf = "terraform",
  },
  pattern = {
    [".*%.go%.tmpl"] = "gotmpl",
    -- Jinja templates rendered by minijinja. Content sniffing only tags a
    -- .html file as htmldjango when a {% %} statement sits in the first 40
    -- lines; without that the buffer stays html, where superhtml attaches and
    -- reports Jinja blocks as invalid HTML nesting.
    [".*/templates/.*%.html"] = "htmldjango",
  },
})
