return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    -- -@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
    },
    keys = {
      -- Top Pickers & Explorer
      {
        '<leader>e',
        function()
          Snacks.explorer()
        end,
        desc = 'File Explorer',
      },
      -- find
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

        end,
      })
    end,
  },
}
