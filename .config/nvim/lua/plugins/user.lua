return {
  -- {
  --   "neo-tree.nvim",
  --   opts = {
  --     window = {
  --       position = "left",
  --     },
  --     filesystem = {
  --       filtered_items = {
  --         visible = true,
  --         hide_dotfiles = false,
  --         hide_gitignored = false,
  --       },
  --     },
  --   },
  -- },
  { "hrsh7th/nvim-cmp", enabled = false },
  { "rcarriga/cmp-dap", enabled = false },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
            T
            .-"-.
            |  ___|
            | (.\/.)
            |  ,,,' 
          | '###
          '----'
            ]],
        },
      },
    },
  },
}
