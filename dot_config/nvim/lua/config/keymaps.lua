local map = vim.keymap.set

-- Set Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better Window Navigation (Ctrl + h/j/k/l)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Same navigation out of any terminal buffer (Claude Code, toggleterm, :terminal)
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("TerminalNav", { clear = true }),
	callback = function(ev)
		for _, key in ipairs({ "h", "j", "k", "l" }) do
			map("t", "<C-" .. key .. ">", "<Cmd>wincmd " .. key .. "<CR>", { buffer = ev.buf, desc = "Move to window " .. key })
		end
	end,
	desc = "Ctrl+h/j/k/l window navigation in terminal mode",
})

-- Resize windows with arrows
map("n", "<C-Up>", ":resize +2<CR>", { desc = "Resize up" })
map("n", "<C-Down>", ":resize -2<CR>", { desc = "Resize down" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Resize left" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Resize right" })

-- Clear search highlights
map("n", "<Esc>", ":nohl<CR>", { desc = "Clear highlights" })

-- Save file
map("n", "<C-s>", ":w<CR>", { desc = "Save file" })

-- Quit
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Toggle Relative Line Numbers
map("n", "<leader>rn", function()
	vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle Relative Numbers" })

-- Scroll 3 lines at a time
map("n", "<ScrollWheelUp>", "2k", { silent = true, desc = "Scroll up" })
map("n", "<ScrollWheelDown>", "2j", { silent = true, desc = "Scroll down" })

-- Enable relative line numbers in insert mode, disable in normal mode
local au = vim.api.nvim_create_augroup("RelativeNumbers", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
	group = au,
	callback = function()
		vim.opt.relativenumber = true
	end,
	desc = "Enable relative numbers in insert mode",
})

vim.api.nvim_create_autocmd("InsertLeave", {
	group = au,
	callback = function()
		vim.opt.relativenumber = false
	end,
	desc = "Disable relative numbers when leaving insert mode",
})

-- Also disable relative numbers when focus is lost
vim.api.nvim_create_autocmd("FocusLost", {
	group = au,
	callback = function()
		if vim.opt.relativenumber:get() then
			vim.opt.relativenumber = false
		end
	end,
	desc = "Disable relative numbers on focus lost",
})

vim.api.nvim_create_autocmd("FocusGained", {
	group = au,
	callback = function()
		if vim.fn.mode() == "i" or vim.fn.mode() == "ic" then
			vim.opt.relativenumber = true
		end
	end,
	desc = "Restore relative numbers on focus gained if in insert mode",
})

-- Toggle diagnostic virtual text
local diagnostics_enabled = true
map("n", "<leader>dt", function()
	diagnostics_enabled = not diagnostics_enabled
	vim.diagnostic.config({ virtual_text = diagnostics_enabled })
end, { desc = "Toggle diagnostic virtual text" })
