local map = vim.keymap.set

-- Set Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better Window Navigation (Ctrl + h/j/k/l)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

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

-- Show diagnostic error in a floating window
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic error" })

-- Jump to next/prev error with [d and ]d
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous error" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next error" })
