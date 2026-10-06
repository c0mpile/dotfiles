-- Shared lualine opts table — referenced by both the plugin config and init.lua
-- for post-theme-load reinitialisation.
local _lualine_opts = (function()
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
				"encoding",
				"fileformat",
				"filetype",
			},
		},
	}
end)()

-- Expose so init.lua can drive reinitialisation after theme load.
_G._lualine_opts = _lualine_opts

return {
	-- Theme: Matugen (base16)
	{
		"RRethy/base16-nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local ok_b16, base16 = pcall(require, "base16-colorscheme")
			if ok_b16 and base16.setup then
				local orig_setup = base16.setup
				local function apply_transparency()
					local transparent_groups = {
						"Normal",
						"NormalNC",
						"NormalFloat",
						"FloatBorder",
						"FloatTitle",
						"SignColumn",
						"FoldColumn",
						"LineNr",
						"EndOfBuffer",
						"NvimTreeNormal",
						"NvimTreeNormalNC",
						"NvimTreeEndOfBuffer",
					}
					for _, group in ipairs(transparent_groups) do
						local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
						hl.bg = nil
						hl.ctermbg = nil
						vim.api.nvim_set_hl(0, group, hl)
					end
				end

				base16.setup = function(colors, config)
					orig_setup(colors, config)
					apply_transparency()
				end
			end

			local ok, matugen = pcall(require, "matugen")
			if ok and matugen.setup then
				matugen.setup()
			end
		end,
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		lazy = false,
		priority = 900,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup(_lualine_opts)
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
