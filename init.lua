vim.g.mapleader = " "
require('telescope').setup();
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
