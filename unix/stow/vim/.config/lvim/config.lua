---- Custom plugins ----
lvim.plugins = {
    { "sainnhe/sonokai" },
    { "weirongxu/plantuml-previewer.vim" },
    { "tyru/open-browser.vim" },
    { "aklt/plantuml-syntax" },
    { "ThePrimeagen/harpoon" },
    { "simrat39/rust-tools.nvim" },
    { "nvim-neotest/neotest" },
    { "nvim-neotest/neotest-python" },
    { "tpope/vim-surround" },
    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" }
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
        config = function()
            require("flutter-tools").setup {
                lsp = {
                    on_attach = require("lvim.lsp").common_on_attach
                },
                dev_log = {
                    enabled = false,
                    notify_errors = true
                },
                debugger = {
                    enabled = true,
                    run_via_dap = true,
                    register_configurations = function(_)
                        require("dap").configurations.dart = {}
                        require("dap.ext.vscode").load_launchjs()
                    end,
                },
            }
        end,
    },
}

---- General ----
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
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

lvim.autocommands = {
    { "ColorScheme", { command = "hi NvimTreeEndOfBuffer ctermbg=none guibg=none" } },
    { "BufWinEnter", { command = ":set formatoptions-=cro" } }
}


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


-- Harpoon
lvim.keys.normal_mode["ø"] = ":Telescope harpoon marks<CR>"
lvim.keys.normal_mode["Ø"] = ":lua require(\"harpoon.mark\").add_file()<CR>"
require("telescope").load_extension('harpoon')


---- Eslint ----
local linters = require "lvim.lsp.null-ls.linters"
linters.setup({
    { command = 'eslint', filetypes = { "typescript", "javascript" } }
})

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
    {
        command = "prettier",
        filetypes = { "typescript", "typescriptreact", "javascript" },
    },
}

---- LSP ----
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "ruff_lsp", "pylyzer", "dartls" })
