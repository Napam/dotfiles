vim.pack.add({
  { src = "https://github.com/folke/which-key.nvim" },
})

require("which-key").setup({})

-- WARN: Register natively, not via wk.add — wk.add() defers to VimEnter
-- (vim.schedule_wrap'd), leaving leader maps dead for ~1s on startup.
-- wk.add() reserved for group labels only.

local map = vim.keymap.set

map("n", "gd", function()
  Snacks.picker.lsp_definitions()
end, { desc = "Goto Definition" })
map("n", "gD", function()
  Snacks.picker.lsp_declarations()
end, { desc = "Goto Declaration" })
map("n", "gr", function()
  Snacks.picker.lsp_references()
end, { nowait = true, desc = "References" })
map("n", "gI", function()
  Snacks.picker.lsp_implementations()
end, { desc = "Goto Implementation" })
map("n", "gy", function()
  Snacks.picker.lsp_type_definitions()
end, { desc = "Goto Type Definition" })

map({ "n", "x", "o" }, "<leader><leader>", function()
  require("flash").jump()
end, { desc = "Flash" })

map("n", "<leader>C", "<cmd>edit ~/.config/nvim/init.lua<cr>", { desc = "Open config" })
map("n", "<leader>c", function()
  Snacks.bufdelete()
end, { desc = "Close buffer" })
map("n", "<leader>e", "<cmd>Oil<cr>", { desc = "File explorer" })
map("n", "<leader>q", "<cmd>q!<cr>", { desc = "Quit buffer" })

-- WARN: <leader>a collides with mc.alignCursors in multicursor.lua. Two-key
-- aa/at/as/al win dispatch; standalone <leader>a only fires with no cursors.
map({ "n", "x", "o" }, "<leader>aa", function()
  require("opencode").ask("@this: ", { submit = true })
end, { desc = "Send to OpenCode" })
map("n", "<leader>at", function()
  require("opencode").toggle()
end, { desc = "Toggle opencode" })
map("n", "<leader>as", function()
  require("opencode").select()
end, { desc = "Opencode select" })
map("n", "<leader>al", function()
  require("opencode").list()
end, { desc = "Opencode list" })
map("n", "<leader>acc", "<cmd>ClaudeCode<cr>")
map("n", "<leader>acm", "<cmd>ClaudeCodeSelectModel<cr>")
map("n", "<leader>acs", "<cmd>ClaudeCodeSend<cr>")

map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Find in buffers" })
map("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Find files" })
map("n", "<leader>fg", function()
  Snacks.picker.grep()
end, { desc = "Find in files" })
map("n", "<leader>fo", function()
  Snacks.picker.recent()
end, { desc = "Recently used files" })
map("n", "<leader>fr", function()
  Snacks.picker.resume()
end, { desc = "Resume finder" })
map("n", "<leader>fs", function()
  Snacks.picker.smart()
end, { desc = "Smart file search" })
map("n", "<leader>fu", function()
  Snacks.picker.undo()
end, { desc = "Undo list" })

map("n", "<leader>gB", "<cmd>Git blame<cr>", { desc = "File blame" })
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", { desc = "Line blame" })
map("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "Git client" })
map("n", "<leader>gj", "<cmd>Gitsigns next_hunk<cr>", { desc = "Next hunk" })
map("n", "<leader>gk", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Previous hunk" })
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk" })

-- WARN: <leader>lf (Format) lives in plugin/conform.lua.
map("n", "<leader>lR", "<cmd>lsp restart<cr>", { desc = "Restart LSP" })
map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>ld", function()
  Snacks.picker.diagnostics()
end, { desc = "Diagnostics picker" })
map("n", "<leader>lj", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next problem" })
map("n", "<leader>lk", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous problem" })
map("n", "<leader>ll", vim.diagnostic.open_float, { desc = "Show problem" })
map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "Signature help" })

map("n", "<leader>ps", function()
  require("persistence").load()
end, { desc = "Load the session for the current directory" })
map("n", "<leader>pS", function()
  require("persistence").select()
end, { desc = "Select a session to load" })
map("n", "<leader>pl", function()
  require("persistence").load({ last = true })
end, { desc = "Load the last session" })
map("n", "<leader>pd", function()
  require("persistence").stop()
end, { desc = "Stop persistence" })

-- WARN: <leader>x prefix collides with mc.deleteCursor layer in multicursor.lua.
-- Layer only active with multiple cursors; xx/xX/etc. work normally otherwise.
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
map(
  "n",
  "<leader>xl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP Definitions / references / ... (Trouble)" }
)
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

map("n", "<leader>Sz", function()
  Snacks.zen()
end, { desc = "Enable zen" })
map("n", "<leader>Sn", function()
  Snacks.notifier.show_history()
end, { desc = "Notification history" })

map("n", "<leader>jc", "<cmd>Neopyter execute notebook:run-cell<cr>", { desc = "Run selected cell" })
map("n", "<leader>js", "<cmd>Neopyter sync current<cr>", { desc = "Sync" })
map("n", "<leader>ja", "<cmd>Neopyter execute notebook:run-all-above<cr>", { desc = "Run all above" })
map("n", "<leader>jb", "<cmd>Neopyter execute notebook:run-all-below<cr>", { desc = "Run all below" })
map("n", "<leader>jA", "<cmd>Neopyter execute runmenu:run-all<cr>", { desc = "Run all" })
map("n", "<leader>jr", "<cmd>Neopyter execute kernelmenu:restart<cr>", { desc = "Restart" })
map("n", "<leader>jR", "<cmd>Neopyter execute notebook:restart-run-all<cr>", { desc = "Restart and run all" })

require("which-key").add({
  { "<leader>a", group = "AI" },
  { "<leader>c", group = "LSP code" },
  { "<leader>f", group = "Find" },
  { "<leader>g", group = "Git" },
  { "<leader>l", group = "LSP" },
  { "<leader>p", group = "Persistence" },
  { "<leader>u", group = "LSP utils" },
  { "<leader>x", group = "Extra diagnostics" },
  { "<leader>S", group = "Snacks" },
  { "<leader>j", group = "Jupyter" },
})
