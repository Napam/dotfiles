---@type vim.lsp.Config
return {
  settings = {
    tailwindCSS = {
      colorDecorators = false,
      experimental = {
        classRegex = {
          -- maud views: classes sit in plain Rust string literals, so the HTML
          -- parser never sees them. Extract the attribute value here instead.
          'class="([^"]*)"',
          "\\w+Class=\\{?['\"]([^'\"]*)\\}?",
          "(?:\\b(?:const|let|var)\\s+)?[\\w$_]*(?:[Ss]tyles|[Cc]lasses|[Cc]lass[Nn]ames|[Cc]lass)[\\w\\d]*\\s*(?:=|\\+=|\\:=)\\s*['\"`]([^'\"`]*)['\"`]",
          { "(?:twMerge|twJoin|Merge|[Cc]lasses|[Aa]dd)\\(([^;]*)[\\);]", "[`'\"`]([^'\"`;]*)[`'\"`]" },
          {
            "(tw`(?:(?:(?:[^`]*\\$\\{[^]*?\\})[^`]*)+|[^`]*`))",
            "((?:(?<=`)(?:[^\"'`]*)(?=\\${|`))|(?:(?<=\\})(?:[^\"'`]*)(?=\\${))|(?:(?<=\\})(?:[^\"'`]*)(?=`))|(?:(?<=')(?:[^\"'`]*)(?='))|(?:(?<=\")(?:[^\"'`]*)(?=\"))|(?:(?<=`)(?:[^\"'`]*)(?=`)))",
          },
        },
      },
    },
  },
}
