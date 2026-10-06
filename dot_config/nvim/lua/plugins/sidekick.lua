return {
	"c0mpile/sidekick.nvim",
	opts = {
		cli = {
			win = {
				layout = "right",
				split = { width = 70 },
			},
			tools = {
				antigravity = { cmd = { "agy" } },
				["antigravity-cli"] = { cmd = { "agy" } },
				gemini = { cmd = { "gemini" } },
			},
		},
	},
	config = function(_, opts)
		require("sidekick").setup(opts)

		-- Force transparency on every highlight group that sidekick's terminal.lua
		-- maps Normal/NormalNC/EndOfBuffer/SignColumn to via winhighlight.
		-- force=true ensures these override any colorscheme that already defined them.
		local function set_transparent_hl()
			vim.api.nvim_set_hl(0, "SidekickChat", { bg = "NONE", ctermbg = "NONE", force = true })
			vim.api.nvim_set_hl(0, "SidekickNormal", { bg = "NONE", ctermbg = "NONE", force = true })
			-- Belt-and-suspenders: also clear Normal/NormalFloat so any fallback
			-- in the winhighlight chain doesn't introduce an opaque bg.
			vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
			vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
		end

		-- Apply now (sidekick's own set_hl already ran inside setup()).
		set_transparent_hl()

		local augroup = vim.api.nvim_create_augroup("sidekick_transparent_bg", { clear = true })

		-- Re-apply whenever the colorscheme changes so the override survives
		-- theme reloads.
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = augroup,
			callback = set_transparent_hl,
		})

		-- sidekick's terminal.lua calls M:wo() inside open_win() and
		-- fix_cursorline(), both of which re-stamp winhighlight onto the window.
		-- We schedule our override so it runs *after* those autocmds settle.
		vim.api.nvim_create_autocmd("WinEnter", {
			group = augroup,
			callback = function()
				local buf = vim.api.nvim_win_get_buf(0)
				if vim.bo[buf].filetype ~= "sidekick_terminal" then
					return
				end
				-- Schedule to ensure we run after sidekick's own WinEnter handler.
				vim.schedule(function()
					local win = vim.api.nvim_get_current_win()
					if not vim.api.nvim_win_is_valid(win) then
						return
					end
					-- Clear the per-window highlight override so SidekickChat
					-- (now transparent) is used directly without indirection.
					vim.wo[win].winblend = 0
					vim.wo[win].winhighlight = ""
					-- Re-stamp the hl groups in case a colorscheme reset them.
					set_transparent_hl()
				end)
			end,
		})
	end,
	keys = {
		-- Toggle the active CLI panel (any mode)
		{
			"<C-.>",
			function()
				require("sidekick.cli").toggle()
			end,
			mode = { "n", "t", "i", "x" },
			desc = "Sidekick: toggle CLI",
		},

		-- <leader>s group ─────────────────────────────────────────────────────
		{
			"<leader>sc",
			function()
				require("sidekick.cli").toggle()
			end,
			desc = "Sidekick: toggle CLI panel",
		},
		{
			"<leader>sa",
			function()
				require("sidekick.cli").toggle({ name = "antigravity", focus = true })
			end,
			desc = "Sidekick: toggle Antigravity CLI",
		},
		{
			"<leader>ss",
			function()
				require("sidekick.cli").select({ name = "antigravity" })
			end,
			desc = "Sidekick: select CLI tool",
		},
		{
			"<leader>sd",
			function()
				require("sidekick.cli").close()
			end,
			desc = "Sidekick: detach CLI session",
		},
		{
			"<leader>st",
			function()
				require("sidekick.cli").send({ msg = "{this}" })
			end,
			mode = { "n", "x" },
			desc = "Sidekick: send this",
		},
		{
			"<leader>sf",
			function()
				require("sidekick.cli").send({ msg = "{file}" })
			end,
			desc = "Sidekick: send file",
		},
		{
			"<leader>sv",
			function()
				require("sidekick.cli").send({ msg = "{selection}" })
			end,
			mode = { "x" },
			desc = "Sidekick: send selection",
		},
		{
			"<leader>sp",
			function()
				require("sidekick.cli").prompt()
			end,
			mode = { "n", "x" },
			desc = "Sidekick: select prompt",
		},

		-- Quick-open specific backends ─────────────────────────────────────────
		{
			"<leader>sg",
			function()
				require("sidekick.cli").toggle({ name = "gemini", focus = true })
			end,
			desc = "Sidekick: toggle Gemini",
		},
		{
			"<leader>so",
			function()
				require("sidekick.cli").toggle({ name = "opencode", focus = true })
			end,
			desc = "Sidekick: toggle opencode",
		},

		-- NES: jump to next hunk or apply the suggestion (normal mode only).
		-- Insert mode is intentionally excluded so Tab is free for blink/copilot.
		-- The fallback returns the actual <Tab> keycode via replace_termcodes to
		-- avoid an infinite expr re-resolution loop.
		{
			"<Tab>",
			function()
				if not require("sidekick").nes_jump_or_apply() then
					return vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
				end
			end,
			mode = { "n" },
			expr = true,
			desc = "NES: jump or apply next edit suggestion",
		},
	},
}
