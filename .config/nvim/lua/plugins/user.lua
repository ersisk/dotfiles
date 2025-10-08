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
  { "akinsho/git-conflict.nvim", version = "*", config = true },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
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

  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
    config = function()
      require("mcphub").setup {
        config = vim.fn.expand "~/.config/mcphub/servers.json",
      }
    end,
  },
}
