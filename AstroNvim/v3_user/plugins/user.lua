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
  { "jwalton512/vim-blade" },
  { "ekalinin/Dockerfile.vim" },
  { "mg979/vim-visual-multi" },
  {
    "Rican7/php-doc-modded",
    as = "php-doc-modded",
    enabled = true,
    lazy = false,
  },
}
