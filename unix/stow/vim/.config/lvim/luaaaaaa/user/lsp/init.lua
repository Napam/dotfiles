vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "ruff_lsp", "pylyzer" })

reload "user.lsp.languages.rust"
