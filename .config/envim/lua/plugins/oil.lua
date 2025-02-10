return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    view_options = { show_hidden = true },
  },
  lazy =false,
  keys = {
    {
      '-',
      function()
        require('oil').open_float()
      end,
      desc = 'Open parent directory with oil',
    },
  },
}
