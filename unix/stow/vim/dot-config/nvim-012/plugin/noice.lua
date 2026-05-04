-- Disabled. To re-enable: drop the ui2 pcall in init.lua first (noice replaces
-- the cmdline UI; ui2 + noice conflict). We use snacks.input, not vim.ui.input
-- via noice — revisit those overrides too.
do return end

if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
  -- nui must be added BEFORE noice: noice's plugin/ scripts may transitively
  -- require nui modules at sourcing time. Same race pattern as dbee → nui.
  vim.pack.add({
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/folke/noice.nvim" },
  })

  require("noice").setup({
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      inc_rename = true,
      lsp_doc_border = true,
    },
  })
end)
