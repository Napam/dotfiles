---- Custom plugins ----
lvim.plugins = {
	{ "sainnhe/sonokai" },
	{ "tyru/open-browser.vim" },
	{ "aklt/plantuml-syntax" },
	{ "ThePrimeagen/harpoon" },
	{ "simrat39/rust-tools.nvim" },
	{ "tpope/vim-surround" },
	{ "mfussenegger/nvim-dap-python" },

	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			"tpope/vim-dadbod",
			-- "kristijanhusak/vim-dadbod-completion" shits fucked,
		},
	},

	{
		"weirongxu/plantuml-previewer.vim",
		dependencies = "tyru/open-browser.vim",
	},
	{
		"iamcco/markdown-preview.nvim",
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	{
		"zbirenbaum/copilot-cmp",
		event = "InsertEnter",
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			vim.defer_fn(function()
				require("copilot").setup()
				require("copilot_cmp").setup()
			end, 100)
		end,
	},
	{
		"akinsho/flutter-tools.nvim",
		dependencies = "nvim-lua/plenary.nvim",
	},
}

---- General ----
vim.opt.relativenumber = true

lvim.log.level = "warn"
lvim.format_on_save = { enabled = false }
lvim.leader = "space"

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"

lvim.builtin.terminal.active = true

lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

lvim.builtin.treesitter.auto_install = true

---- Aesthetics ----
lvim.transparent_window = true
lvim.colorscheme = "sonokai"

vim.api.nvim_create_autocmd("ColorScheme", { command = "hi NvimTreeEndOfBuffer ctermbg=none guibg=none" })
vim.api.nvim_create_autocmd("BufWinEnter", { command = ":set formatoptions-=cro" })

---- Custom options and such ----
vim.opt.relativenumber = true
vim.opt.smartindent = true

---- Keybindings ----
lvim.keys.normal_mode["<leader>o"] = "o<ESC>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<leader>F"] = ":Telescope live_grep<CR>"
lvim.lsp.buffer_mappings.normal_mode["gr"] = { "<cmd>Telescope lsp_references<cr>", "Go to Definiton" }
lvim.builtin.terminal.open_mapping = "<c-t>"
lvim.builtin.which_key.mappings["lR"] = { "<cmd>LspRestart<cr>", "Lsp Restart" }
lvim.builtin.which_key.mappings["Q"] = { "<cmd>qa!<cr>", "Quit all" }

-- Dadbod
-- vim.api.nvim_create_autocmd(
-- 	"FileType",
-- 	{ pattern = { "dbui" }, command = ":nmap <buffer> l <Plug>(DBUI_SelectLineVsplit)" }
-- )

-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = { "sql", "mysql", "plsql" },
-- 	command = "lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })",
-- })

-- Harpoon
lvim.keys.normal_mode["ø"] = "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>"
lvim.keys.normal_mode["Ø"] = ':lua require("harpoon.mark").add_file()<CR>'
require("telescope").load_extension("harpoon")

-- Imports
require("user.lsp")
