return {
	-- Theme: Nightfox (Carbonfox variant)
	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("nightfox").setup({
				options = {
					transparent = true,
				},
			})
			vim.cmd("colorscheme carbonfox")
		end,
	},

	-- Statusline (Clean & Robust)
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = function()
			-- Safe Hex Codes for Powerline Arrows
			local left_hard = vim.fn.nr2char(0xe0b0)
			local right_hard = vim.fn.nr2char(0xe0b2)
			local left_soft = vim.fn.nr2char(0xe0b1)
			local right_soft = vim.fn.nr2char(0xe0b3)

			return {
				options = {
					theme = "auto",
					globalstatus = true,
					component_separators = { left = left_soft, right = right_soft },
					section_separators = { left = left_hard, right = right_hard },
				},

				sections = {
					lualine_x = {
						{
							function()
								local ok, config = pcall(require, "avante.config")
								if ok and config.provider then
									-- 1. Get the config for the active provider
									local active_provider = config.providers and config.providers[config.provider]

									-- 2. If we found it and it has a 'model' field, return that
									if active_provider and active_provider.model then
										return " " .. active_provider.model
									end

									-- Fallback: just return the provider name if model isn't found
									return " " .. config.provider
								end
								return ""
							end,
							color = { fg = "#a6e3a1" }, -- Green color for the icon
						},
						"encoding",
						"fileformat",
						"filetype",
					},
				},
			}
		end,
	},

	-- File Explorer
	{
		"nvim-tree/nvim-tree.lua",
		cmd = { "NvimTreeToggle", "NvimTreeFocus" },
		keys = {
			{ "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
		},
		opts = {
			view = {
				width = 30,
				adaptive_size = true,
			},
			renderer = {
				group_empty = true,
				icons = {
					show = {
						file = true,
						folder = true,
						folder_arrow = true,
						git = true,
					},
				},
			},
			filters = { dotfiles = false },
			sync_root_with_cwd = true,
			respect_buf_cwd = true,
			update_focused_file = {
				enable = true,
				update_root = true,
			},
			actions = {
				open_file = {
					quit_on_open = false,
					window_picker = {
						enable = true,
						picker = "default",
						chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
						exclude = {
							filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
							buftype = { "nofile", "terminal", "help" },
						},
					},
				},
			},
		},
	},

	-- Keybinding Helper
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
	},
}
