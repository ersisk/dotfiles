return {
  {
    "rcarriga/nvim-notify",
    opts = {
      background_colour = "#000000",
      fps = 30,
      level = 2,
      minimum_width = 50,
      render = "simple",
      stages = "fade",
      timeout = 3000,
      top_down = true,
    },
  },
  {
    "neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
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
}
