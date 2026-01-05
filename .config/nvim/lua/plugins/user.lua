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
  { "akinsho/git-conflict.nvim", version = "*", config = true },
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
  {
    "adibhanna/nvim-newfile.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("nvim-newfile").setup {
        -- Optional configuration
      }
    end,
  },
}
