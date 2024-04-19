return {
 {
    "stevearc/oil.nvim",
    cmd = "Oil",
    lazy = false,
    opts = {},
    config = function()
      require("oil").setup()
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end 
  },
  {
    "rebelot/heirline.nvim",
    optional = true,
    opts = function(_, opts)
      if opts.winbar then
        table.insert(opts.winbar, 1, {
          condition = function(self) return is_oil(self.bufnr) end,
          status.component.separated_path {
            padding = { left = 2 },
            max_depth = false,
            suffix = false,
            path_func = function() return require("oil").get_current_dir() end,
          },
        })
      end
    end,
  },
}
