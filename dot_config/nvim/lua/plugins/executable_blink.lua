return {
	"saghen/blink.cmp",
	version = "*",
	opts = {
		keymap = {
			preset = "default",

			-- 1. Navigation (Vim Style)
			["<C-n>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },

			-- 2. Accept with Ctrl-Space
			-- Logic: Try to 'accept' first. If menu isn't open, 'show' it instead.
			["<C-Space>"] = { "accept", "show", "fallback" },

			-- 3. Enter/Space are boring (Standard typing)
			["<CR>"] = { "fallback" }, -- Enter just creates a new line
			["<Space>"] = { "fallback" }, -- Space just adds a space

			-- 4. UNBIND TAB (Leave it for Copilot)
			["<Tab>"] = {},
			["<S-Tab>"] = {},
		},

		-- (Optional) Make sure the list is visible for this to feel good
		completion = {
			list = { selection = { preselect = false, auto_insert = true } },
			menu = { auto_show = true },
		},
	},
}
