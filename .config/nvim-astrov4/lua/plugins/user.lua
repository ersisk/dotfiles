return {
  {
    "rcarriga/nvim-notify",
    opts = {
      background_colour = "#000000",
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
  { "mg979/vim-visual-multi", event = "VeryLazy", enabled = true },
  { "christoomey/vim-tmux-navigator", lazy = false },
}
