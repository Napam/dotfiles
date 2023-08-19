vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, {
    "ruff_lsp",
    "pylyzer",
    "dartls",
    "rust_analyzer"
})

---- Eslint ----
local linters = require "lvim.lsp.null-ls.linters"
linters.setup({
    { command = 'eslint', filetypes = { "typescript", "javascript" } }
})

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
    { command = "stylua",   filetypes = { "lua" } },
    { command = "shfmt",    filetypes = { "sh", "zsh" } },
    { command = "prettier", filetypes = { "css", "javascript", "javascriptreact", "typescript", "typescriptreact" } },
}

-- Rust
local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")
-- local extension_path = mason_path .. "/packages/codelldb/extension"
-- local codelldb_path = extension_path .. "/adapter/codelldb"
-- local liblldb_path = extension_path .. "/lldb/lib/liblldb.dylib"

local codelldb_adapter = {
    type = "server",
    port = "${port}",
    executable = {
        command = mason_path .. "bin/codelldb",
        args = { "--port", "${port}" },
    },
}

require("rust-tools").setup({
    tools = {
        executor = require("rust-tools/executors").termopen, -- can be quickfix or termopen
        reload_workspace_from_cargo_toml = true,
        inlay_hints = {
            auto = true,
            only_current_line = false,
            show_parameter_hints = false,
            parameter_hints_prefix = "<-",
            other_hints_prefix = "=>",
            max_len_align = false,
            max_len_align_padding = 1,
            right_align = false,
            right_align_padding = 7,
            highlight = "Comment",
        },
        hover_actions = {
            auto_focus = true,
        },
    },
    server = {
        on_attach = require("lvim.lsp").common_on_attach,
        on_init = require("lvim.lsp").common_on_init,
    },
    dap = {
        adapter = codelldb_adapter
    }
})

local dap = require("dap")
dap.adapters.codelldb = codelldb_adapter
dap.configurations.rust = {
    {
        name = "Launch file",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}


-- Flutter
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
