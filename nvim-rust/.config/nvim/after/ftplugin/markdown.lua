-- Markdown specific folding configuration
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt_local.foldlevel = 2
vim.opt_local.foldenable = true
vim.opt_local.foldtext = ''
vim.opt_local.fillchars = 'fold: '

-- Optional: Set fold column to visualize fold levels
vim.opt_local.foldcolumn = '1'

-- Optional: Define which heading levels to fold by default
-- Level 0 = all folded, 99 = all unfolded
-- Level 2 means headings level 3 and deeper will be folded
vim.opt_local.foldlevelstart = 2

-- Markdown-specific folding keymaps
vim.keymap.set('n', 'za', 'za', { buffer = true, desc = 'Toggle fold under cursor' })
vim.keymap.set('n', 'zA', 'zA', { buffer = true, desc = 'Toggle all folds under cursor' })
vim.keymap.set('n', 'zc', 'zc', { buffer = true, desc = 'Close fold under cursor' })
vim.keymap.set('n', 'zo', 'zo', { buffer = true, desc = 'Open fold under cursor' })
vim.keymap.set('n', 'zC', 'zC', { buffer = true, desc = 'Close all folds under cursor' })
vim.keymap.set('n', 'zO', 'zO', { buffer = true, desc = 'Open all folds under cursor' })
vim.keymap.set('n', 'zM', 'zM', { buffer = true, desc = 'Close all folds in document' })
vim.keymap.set('n', 'zR', 'zR', { buffer = true, desc = 'Open all folds in document' })
vim.keymap.set('n', 'zm', 'zm', { buffer = true, desc = 'Increase fold level' })
vim.keymap.set('n', 'zr', 'zr', { buffer = true, desc = 'Decrease fold level' })