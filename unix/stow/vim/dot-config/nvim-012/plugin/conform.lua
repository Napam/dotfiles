if Config.only_essential_plugins() then return end

require("lazyload").on_vim_enter(function()
	vim.g.auto_format = true

	vim.pack.add({
		{ src = "https://github.com/stevearc/conform.nvim" },
	})

	require("conform").setup({
		formatters_by_ft = {
			dependabot = { "prettierd" },
			gha = { "prettierd" },
			javascript = { "prettierd" },
			javascriptreact = { "prettierd" },
			json = { "biome" },
			json5 = { "biome" },
			jsonc = { "biome" },
			lua = { "stylua" },
			markdown = { "prettierd" },
			nix = { "nixfmt" },
			proto = { "buf" },
			sh = { "shfmt" },
			terraform = { "terraform_fmt" },
			["terraform-vars"] = { "terraform_fmt" },
			tf = { "terraform_fmt" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
			yaml = { "prettierd" },
		},

		formatters = {
			biome = {
				args = { "format", "--indent-style", "space", "--stdin-file-path", "$FILENAME" },
			},
			mdformat = {
				prepend_args = { "--number", "--wrap", "110" },
			},
			prettier = {
				prepend_args = { "--prose-wrap", "always", "--print-width", "110", "--tab-width", "2" },
			},
			yamlfmt = {
				prepend_args = {
					"-formatter",
					"retain_line_breaks_single=true",
					"-formatter",
					"pad_line_comments=2",
				},
			},
		},
	})

	vim.keymap.set("n", "<leader>uf", function()
		vim.g.auto_format = not vim.g.auto_format
		vim.notify("Auto-format: " .. (vim.g.auto_format and "on" or "off"))
	end, { desc = "Toggle auto-format" })
end)
