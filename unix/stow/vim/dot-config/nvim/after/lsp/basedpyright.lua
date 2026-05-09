---@type vim.lsp.Config
return {
	settings = {
		basedpyright = {
			analysis = {
				typeCheckingMode = "standard",
				diagnosticSeverityOverrides = {
					reportImplicitStringConcatenation = false,
					-- Let linter handle unused stuff, or will have double up with essentially same message
					reportUnusedImport = false,
					reportUnusedVariable = false,
				},
			},
		},
	},
}
