local prefix = "<Leader>A"
return {
  "yetone/avante.nvim",
  opts = {
    mappings = {
      toggle = {
        selection = prefix .. "C",
      },
      zen_mode = prefix .. "z",
    },
  },
}
