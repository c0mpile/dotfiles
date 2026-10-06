return {
	-- Mason: Package manager for LSP servers, DAP servers, linters, and formatters
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {},
	},

	-- SchemaStore: Provides schemas for JSON and YAML files to improve LSP support
	{ "b0o/schemastore.nvim" },

	-- nvim-lspconfig: Configuration bridge for the built-in Neovim LSP client
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"saghen/blink.cmp",
			"b0o/schemastore.nvim",
		},
		config = function()
			-- Capabilities are required for completion engines like blink.cmp
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Defined server list with their specific configurations
			local servers = {
				ansiblels = {},
				bashls = {},
				cssls = {},
				cssmodules_ls = {},
				dockerls = {},
				docker_compose_language_service = {},
				html = {},
				jdtls = {},
				jsonls = {
					settings = {
						json = {
							schemas = require("schemastore").json.schemas(),
							validate = { enable = true },
						},
					},
				},
				lua_ls = {
					settings = {
						Lua = {
							-- Recognize 'vim' as a global variable
							diagnostics = { globals = { "vim" } },
							-- Make the server aware of Neovim runtime files for autocompletion
							workspace = { library = vim.api.nvim_get_runtime_file("", true) },
						},
					},
				},
				markdown_oxide = {},
				pyright = {},
				rust_analyzer = {},
				taplo = {},
				ts_ls = {},
				vimls = {},
				yamlls = {
					settings = {
						yaml = {
							-- Use SchemaStore for YAML validation and autocompletion
							schemaStore = { enable = false, url = "" },
							schemas = require("schemastore").yaml.schemas(),
						},
					},
				},
			}

			-- Extract server names to ensure they are installed by Mason
			local ensure_installed = vim.tbl_keys(servers)

			-- Additional non-LSP tools to be managed by mason-tool-installer
			vim.list_extend(ensure_installed, {
				"stylua",
				"black",
				"isort",
				"shellcheck",
				"beautysh",
				"cpptools",
			})

			-- Automatically install and update the specified tools and servers
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- Loop through the servers and apply their configurations using Neovim 0.11+ API
			for server_name, config in pairs(servers) do
				config.capabilities = capabilities

				-- Register the server configuration in the internal LSP table
				vim.lsp.config[server_name] = config

				-- Globally enable the server to start when a matching filetype is opened
				vim.lsp.enable(server_name)
			end
		end,
	},

	-- blink.cmp: Modern and performant completion engine for Neovim
	{
		"saghen/blink.cmp",
		lazy = false,
		dependencies = "rafamadriz/friendly-snippets",
		version = "*",
		opts = {
			keymap = { preset = "default" },
			appearance = {
				-- Sync with nvim-cmp's default appearance if applicable
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},
			sources = {
				-- Order of priority for completion sources
				default = { "lsp", "path", "snippets", "buffer" },
			},
			-- Enable signature help support
			signature = { enabled = true },
		},
	},
}
