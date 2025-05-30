return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig",
	},
	config = function()
		local mason = require("mason")

		mason.setup({
			ui = {
				icons = {
					package_installed = "",
					package_uninstalled = "",
					package_pending = "",
				},
			},
		})

		require("mason-lspconfig").setup({
			ensure_installed = {
				"html",
				"ts_ls",
				"lua_ls",
				"pyright",
				"csharp-language-server",
				"csharpier",
				"omnisharp",
				"json-lsp",
				"javascript",
				"zls",
				"prettier",
				"black",
				"esline",
				"unocss-language-server",
				"tailwindcss",
			},
		})
	end,
}
