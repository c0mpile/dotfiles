local opt = vim.opt

-- DISABLE NETRW (Standard File Browser)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Appearance
opt.number = true -- Show line numbers
opt.relativenumber = true -- Relative line numbers
opt.signcolumn = "yes" -- Always show sign column
opt.termguicolors = true -- True color support
opt.cursorline = true -- Highlight current line

-- Behavior
opt.mouse = "a" -- Enable mouse mode
opt.ignorecase = true -- Ignore case
opt.smartcase = true -- Don't ignore case with capitals
opt.timeoutlen = 300 -- Faster completion wait time
opt.updatetime = 250 -- Faster update time
opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.wrap = true -- Disable line wrapping
opt.hidden = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.softtabstop = 2

-- Split behavior
opt.splitright = true
opt.splitbelow = true

-- Save undo history
opt.undofile = true
