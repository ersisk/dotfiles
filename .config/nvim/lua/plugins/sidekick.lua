return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      win = {
        layout = "right", -- Options: "float", "left", "bottom", "top", "right"
        -- Settings for split windows (left/right/top/bottom)
        split = {
          width = 50, -- Default fixed width in columns
          height = 20, -- Default fixed height in rows
        },
        -- Settings for floating windows
        float = {
          width = 0.8, -- Relative width (0.0 to 1.0)
          height = 0.8, -- Relative height (0.0 to 1.0)
        },
      },
    },
  },
}
