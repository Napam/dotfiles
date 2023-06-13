lvim.leader = "space"

lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<leader>o"] = "o<ESC>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<leader>F"] = ":Telescope live_grep<CR>"
lvim.keys.normal_mode["ø"] = ":lua require(\"harpoon.ui\").toggle_quick_menu()<CR>"
lvim.keys.normal_mode["æ"] = ":lua require(\"harpoon.mark\").add_file()<CR>"

lvim.lsp.buffer_mappings.normal_mode["gr"] = { "<cmd>Telescope lsp_references<cr>", "Go to Definiton" }
lvim.builtin.terminal.open_mapping = "<c-t>"

