return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("copilot").setup({
			panel = { enabled = false }, -- NES via sidekick.nvim is preferred
			suggestion = {
				enabled = true,
				auto_trigger = true,
				hide_during_completion = false,
				debounce = 75,
				keymap = {
					accept = false, -- Tab is never owned by copilot; use <M-Tab> below
					accept_word = "<M-w>",
					accept_line = "<M-l>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
		})

		-- Explicit accept key: <M-Tab>. Tab is intentionally left free.
		vim.keymap.set("i", "<M-Tab>", function()
			if require("copilot.suggestion").is_visible() then
				require("copilot.suggestion").accept()
			end
		end, { silent = true, desc = "Copilot: accept suggestion" })

		-- Ensure CopilotSuggestion highlight group is visible against dark/transparent backgrounds
		vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#6c7086", default = false })
		vim.api.nvim_create_autocmd("ColorScheme", {
			pattern = "*",
			callback = function()
				vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#6c7086", default = false })
			end,
		})
	end,
}
