return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
  { "jwalton512/vim-blade",    event = "VeryLazy"},
  { "ekalinin/Dockerfile.vim", event = "VeryLazy"},
  { "mg979/vim-visual-multi",  event = "VeryLazy", enabled= true}, 
  { "christoomey/vim-tmux-navigator", lazy = false }
}
