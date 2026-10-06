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

			-- 3. S-Tab: always highlight the first (next) menu item.
			--    Tab: literal tab — never touches the menu.
			["<S-Tab>"] = { "select_next", "fallback" },
			["<Tab>"] = { "fallback" },

			-- 4. Arrow keys: conditional navigation.
			--    Only route to menu when visible AND an item is already selected.
			--    Otherwise fall back to normal cursor movement.
			["<Down>"] = {
				function(cmp)
					if cmp.is_visible() and cmp.get_selected_item() ~= nil then
						return cmp.select_next()
					end
				end,
				"fallback",
			},
			["<Up>"] = {
				function(cmp)
					if cmp.is_visible() and cmp.get_selected_item() ~= nil then
						return cmp.select_prev()
					end
				end,
				"fallback",
			},

			-- 5. Enter/Space are boring (Standard typing)
			["<CR>"] = { "fallback" }, -- Enter just creates a new line
			["<Space>"] = { "fallback" }, -- Space just adds a space
		},

		-- (Optional) Make sure the list is visible for this to feel good
		completion = {
			list = { selection = { preselect = false, auto_insert = true } },
			menu = { auto_show = true },
		},
	},
}
