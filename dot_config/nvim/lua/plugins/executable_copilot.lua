return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			suggestion = {
				enabled = true,
				auto_trigger = true,
				keymap = {
					accept = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
		})

		-- Custom Toggle Logic: Accept if visible, else Tab
		vim.keymap.set("i", "<Tab>", function()
			if require("copilot.suggestion").is_visible() then
				require("copilot.suggestion").accept()
			else
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
			end
		end, { desc = "Super Tab: Copilot Accept or Tab" })
	end,
}
