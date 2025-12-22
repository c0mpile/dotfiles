return {
	-- 1. Mason (The Installer)
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {},
	},

	-- 2. SchemaStore (Sane defaults for JSON/YAML)
	{ "b0o/schemastore.nvim" },

	-- 3. LSP Config & Tool Installer
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim", -- ADDED
			"saghen/blink.cmp",
			"b0o/schemastore.nvim",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Server List
			local servers = {
				ansiblels = {},
				bashls = {},
				cmake = {},
				cssls = {},
				cssmodules_ls = {},
				dockerls = {},
				docker_compose_language_service = {},
				html = {},
				hyprls = {},
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
							diagnostics = { globals = { "vim" } },
							workspace = { library = vim.api.nvim_get_runtime_file("", true) },
						},
					},
				},
				markdown_oxide = {},
				pyright = {},
				qmlls = {},
				rust_analyzer = {},
				taplo = {},
				ts_ls = {},
				vimls = {},
				yamlls = {
					settings = {
						yaml = {
							schemaStore = { enable = false, url = "" },
							schemas = require("schemastore").yaml.schemas(),
						},
					},
				},
			}

			-- 1. Get LSP names from the table above
			local ensure_installed = vim.tbl_keys(servers)

			-- 2. Add your NON-LSP tools (Formatters/Linters)
			vim.list_extend(ensure_installed, {
				"stylua",
				"black",
				"isort",
				"shellcheck",
				"beautysh",
				"cpptools",
				"cmakelang",
			})

			-- 3. Install everything
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			for server_name, config in pairs(servers) do
				config.capabilities = capabilities

				-- 1. Apply the configuration to the native table (replaces .setup)
				vim.lsp.config[server_name] = config

				-- 2. Explicitly enable the server so it starts on relevant filetypes
				vim.lsp.enable(server_name)
			end
		end,
	},
	-- 4. Blink.cmp
	{
		"saghen/blink.cmp",
		lazy = false,
		dependencies = "rafamadriz/friendly-snippets",
		version = "*",
		opts = {
			keymap = { preset = "default" },
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			signature = { enabled = true },
		},
	},
}
