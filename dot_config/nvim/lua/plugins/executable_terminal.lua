return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm" },
    keys = {
      -- Your requested keymaps
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal Vertical" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal Horizontal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal Float" }, -- Bonus: Floating terminal
    },
    config = function()
      require("toggleterm").setup({
        -- Dynamic sizing
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        
        open_mapping = [[<c-\>]], -- Press Ctrl+\ to toggle the current terminal
        hide_numbers = true,      -- Hide line numbers in terminal
        shade_terminals = true,   -- Darken terminal background slightly
        start_in_insert = true,   -- Start typing immediately
        insert_mappings = true,   -- Use keybindings in insert mode
        terminal_mappings = true, -- Use keybindings in normal mode
        persist_size = true,
        close_on_exit = true,     -- Close window when terminal exits
        shell = vim.o.shell,      -- Use your default shell (zsh/bash)
      })

      -- BETTER NAVIGATION: Allow using Ctrl+h/j/k/l to move OUT of the terminal window
      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
      end

      -- Auto-apply these maps when a terminal opens
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
    end,
  }
}
