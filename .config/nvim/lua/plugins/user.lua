return {
  {
    "neo-tree.nvim",
    opts = {
      window = {
        position = "left",
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
  { "hrsh7th/nvim-cmp", enabled = false },
  { "rcarriga/cmp-dap", enabled = false },
  { "christoomey/vim-tmux-navigator", lazy = false },
  { "mbbill/undotree", lazy = false },
  { "akinsho/git-conflict.nvim", version = "*", config = true },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            "",
            "███    ██ ██    ██ ██ ███    ███",
            "████   ██ ██    ██ ██ ████  ████",
            "██ ██  ██ ██    ██ ██ ██ ████ ██",
            "██  ██ ██  ██  ██  ██ ██  ██  ██",
            "██   ████   ████   ██ ██      ██",
          }, "\n"),
        },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
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
