-- You can also add or configure plugins by creating files in this `plugins/` folder
-- PLEASE REMOVE THE EXAMPLES YOU HAVE NO INTEREST IN BEFORE ENABLING THIS FILE
-- Here are some examples:

---@type LazySpec
return {
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
  {
    "sphamba/smear-cursor.nvim",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      distance_stop_animating = 0.5,
      hide_target_hack = false,
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      legacy_computing_symbols_support = false,
    },
  },
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
    "m4xshen/smartcolumn.nvim",
    opts = {
      colorcolumn = "118",
    },
  },
  {
    "pwntester/octo.nvim",
    keys = {
      {
        "<leader>gD",
        function()
          local buffer = require("octo.utils").get_current_buffer()
          if not buffer or not buffer:isPullRequest() then
            vim.notify("Not in an Octo PR buffer", vim.log.levels.WARN)
            return
          end
          local pr = buffer:pullRequest()
          -- PR branches are often not checked out locally; prefer the remote ref when it exists
          local function ref(name)
            if vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", "origin/" .. name }) ~= "" then
              return "origin/" .. name
            end
            return name
          end
          vim.cmd(("CodeDiff %s %s"):format(ref(pr.baseRefName), ref(pr.headRefName)))
        end,
        desc = "CodeDiff for current PR",
      },
    },
  },
}
