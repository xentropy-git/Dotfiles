return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
			end,
		})

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.INFO] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
				},
				linehl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticError",
					[vim.diagnostic.severity.WARN] = "DiagnosticWarn",
					[vim.diagnostic.severity.INFO] = "DiagnosticInfo",
					[vim.diagnostic.severity.HINT] = "DiagnosticHint",
				},
				numhl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticError",
					[vim.diagnostic.severity.WARN] = "DiagnosticWarn",
					[vim.diagnostic.severity.INFO] = "DiagnosticInfo",
					[vim.diagnostic.severity.HINT] = "DiagnosticHint",
				},
			},
		})

		mason_lspconfig.setup_handlers({
			-- default handler for installed servers
			function(server_name)
				lspconfig[server_name].setup({
					capabilities = capabilities,
				})
			end,
			["lua_ls"] = function()
				-- configure lua server (with special settings)
				lspconfig["lua_ls"].setup({
					capabilities = capabilities,
					settings = {
						Lua = {
							-- make the language server recognize "vim" global
							diagnostics = {
								globals = { "vim" },
							},
							completion = {
								callSnippet = "Replace",
							},
							runtime = {
								version = "LuaJIT",
								path = vim.split(package.path, ";"),
							},
							workspace = {
								library = { vim.env.VIMRUNTIME },
								checkThirdParty = false,
							},
							telemetry = {
								enable = false,
							},
						},
					},
				})
			end,
		})

		-- Function to restart mojo LSP server if it crashes
		local function restart_mojo_lsp()
			-- Use `vim.schedule` to safely run the LspStart command
			vim.schedule(function()
				print("Restarting mojo-lsp-server...")
				vim.cmd("LspStart mojo")
			end)
		end

		local util = require("lspconfig.util")
		lspconfig.mojo.setup({
			capabilities = capabilities,
			root_dir = function(fname)
				-- Use lspconfig's utility function to search for mojoproject.toml in parent directories
				return util.root_pattern("mojoproject.toml")(fname) or util.find_git_ancestor(fname) or vim.fn.getcwd()
			end,
			-- Additional configuration (if needed)
			on_attach = function(client, _)
				print("Mojo LSP attached to " .. client.name)
			end,
			-- This is a workaround for the fact that the mojo lsp server
			-- keeps crashing in neovim as of 12/2024.  I have an open issue
			-- but no progress is being made.
			on_exit = function(_, code, _)
				if code ~= 0 then
					print("mojo-lsp-server has crashed, restarting...")
					restart_mojo_lsp()
				end
			end,
		})

		-- workaround for omnisharp semantic tokens...
		local omni_on_attach = function(client, bufnr)
			if client.name == "omnisharp" then
				client.server_capabilities.semanticTokensProvider = {
					full = vim.empty_dict(),
					legend = {
						tokenModifiers = { "static_symbol" },
						tokenTypes = {
							"comment",
							"excluded_code",
							"identifier",
							"keyword",
							"keyword_control",
							"number",
							"operator",
							"operator_overloaded",
							"preprocessor_keyword",
							"string",
							"whitespace",
							"text",
							"static_symbol",
							"preprocessor_text",
							"punctuation",
							"string_verbatim",
							"string_escape_character",
							"class_name",
							"delegate_name",
							"enum_name",
							"interface_name",
							"module_name",
							"struct_name",
							"type_parameter_name",
							"field_name",
							"enum_member_name",
							"constant_name",
							"local_name",
							"parameter_name",
							"method_name",
							"extension_method_name",
							"property_name",
							"event_name",
							"namespace_name",
							"label_name",
							"xml_doc_comment_attribute_name",
							"xml_doc_comment_attribute_quotes",
							"xml_doc_comment_attribute_value",
							"xml_doc_comment_cdata_section",
							"xml_doc_comment_comment",
							"xml_doc_comment_delimiter",
							"xml_doc_comment_entity_reference",
							"xml_doc_comment_name",
							"xml_doc_comment_processing_instruction",
							"xml_doc_comment_text",
							"xml_literal_attribute_name",
							"xml_literal_attribute_quotes",
							"xml_literal_attribute_value",
							"xml_literal_cdata_section",
							"xml_literal_comment",
							"xml_literal_delimiter",
							"xml_literal_embedded_expression",
							"xml_literal_entity_reference",
							"xml_literal_name",
							"xml_literal_processing_instruction",
							"xml_literal_text",
							"regex_comment",
							"regex_character_class",
							"regex_anchor",
							"regex_quantifier",
							"regex_grouping",
							"regex_alternation",
							"regex_text",
							"regex_self_escaped_character",
							"regex_other_escape",
						},
					},
					range = true,
				}
			end
		end

		lspconfig.omnisharp.setup({
			capabilities = capabilities,
			on_attach = omni_on_attach,
			cmd = { "omnisharp" },
			enable_ms_build_load_projects_on_demand = false,
			enable_editorconfig_support = true,
			enable_roslyn_analyzers = true,
			enable_import_completion = true,
			organize_imports_on_format = true,
			enable_decompilation_support = true,
			analyze_open_documents_only = false,
			filetypes = { "cs", "vb", "csproj", "sln", "slnx", "csx", "targets", "razor" },
			root_dir = function()
				return vim.fn.getcwd()
			end,
		})

		lspconfig.zls.setup({
			cmd = { "zls" },
			settings = {
				zls = {
					enable_build_on_save = true,
				},
			},
		})

		lspconfig.ts_ls.setup({})
	end,
}
