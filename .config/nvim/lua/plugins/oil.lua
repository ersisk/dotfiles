return {
  {
    "oil.nvim",
    lazy = false,
    opts = {
      skip_confirm_for_simple_edits = true,
      delete_to_trash = false,
      --trash_command = "trash",
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = false,
      },
    },
    keys = {
      {
        "-",
        function() return require("oil").open() end,
        desc = "Open parent directory",
      },
    },
  },
}
