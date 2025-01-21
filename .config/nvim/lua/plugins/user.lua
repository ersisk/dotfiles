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
  {
    "goolord/alpha-nvim",
    opts = function(_, opts)
      -- customize the dashboard header
      opts.section.header.val = {
        "  __      _____ ____",
        " /---__  ( (O)|/(O) )",
        "  \\\\\\\\/  \\___/U\\___/",
        "    L\\       ||",
        "     \\\\ ____|||_____",
        "      \\\\|==|[]__/==|\\-|",
        "       \\|* |||||\\==|/-|",
        "    ____| *|[][]-- |_",
        "   ||EEE|__EEEE_[]_|EE\\",
        "   ||EEE|=O     O|=|EEE|",
        "   \\LEEE|         \\|EEE|  __))",
        "                          ```",
      }
      return opts
    end,
  },
  { "mbbill/undotree", lazy = false },
}
