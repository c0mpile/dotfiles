return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			-- Add this line:
			python = { "isort", "black" },

			lua = { "stylua" },
			java = { "google-java-format" },
			javascript = { "prettier" },
		},
		format_on_save = {
			timeout_ms = 1000,
			lsp_fallback = true,
		},
	},
}
