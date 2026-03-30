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
}
