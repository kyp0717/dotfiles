return {
  'folke/todo-comments.nvim',
  event = 'VimEnter', -- Load the plugin when Neovim starts
  dependencies = { 'nvim-lua/plenary.nvim' }, -- Ensure plenary.nvim is installed
  opts = {
    signs = true, -- Show icons in the sign column
    keywords = {
      FIX = { icon = ' ', color = 'error', alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' } },
      TODO = { icon = ' ', color = 'info' },
      HACK = { icon = ' ', color = 'warning' },
      WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
      PERF = { icon = '⚡', color = 'default', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
      NOTE = { icon = '📝', color = 'hint', alt = { 'INFO' } },
    },
  },
}
