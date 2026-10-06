-- ---------------------------------------------------------------------------
-- claudecode.lua — Claude Code CLI integration (coder/claudecode.nvim)
--
-- Speaks the same WebSocket/MCP protocol as the official IDE extensions, so
-- the `claude` CLI running in the side terminal can read selections, open
-- files and propose diffs that are reviewed natively in Neovim.
-- ---------------------------------------------------------------------------

return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSend",
		"ClaudeCodeAdd",
		"ClaudeCodeTreeAdd",
		"ClaudeCodeSelectModel",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
	},
	opts = {
		terminal = {
			split_side = "right",
			split_width_percentage = 0.35,
		},
		diff_opts = {
			layout = "vertical",
			open_in_new_tab = false,
		},
	},
	init = function()
		local ok_wk, wk = pcall(require, "which-key")
		if ok_wk and wk.add then
			wk.add({
				{ "<leader>a", group = "Claude Code" },
			})
		end
	end,
	keys = {
		-- Ask: add the current buffer, or send the visual selection, as context
		{ "<leader>aa", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: add current buffer" },
		{ "<leader>aa", "<cmd>ClaudeCodeSend<cr>", mode = "x", desc = "Claude: send selection" },

		-- Diff review
		{ "<leader>ae", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
		{ "<leader>ak", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject diff" },

		-- Session / window
		{ "<leader>at", "<cmd>ClaudeCode<cr>", desc = "Claude: toggle terminal" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: focus terminal" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: resume session" },
		{ "<leader>ao", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: continue last session" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude: select model" },
	},
}
