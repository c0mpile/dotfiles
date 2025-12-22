return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			-- Add this line:
			python = { "isort", "black" },

			lua = { "stylua" },
			javascript = { "prettier" },
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
	},
}
