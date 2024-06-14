-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  {
    "m4xshen/smartcolumn.nvim",
    opts = {
      colorcolumn = "118",
    },
  },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.colorscheme.onedarkpro-nvim" },
  { import = "astrocommunity.programming-language-support.rest-nvim" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.docker" },
  { import = "astrocommunity.pack.blade" },
  { import = "astrocommunity.markdown-and-latex.glow-nvim" },
  { import = "astrocommunity.motion.vim-matchup" },
  { import = "astrocommunity.motion.harpoon" },
  { import = "astrocommunity.lsp.lsp-signature-nvim", enabled = true },
  { import = "astrocommunity.file-explorer.oil-nvim" },
  {
    "oil.nvim",
    lazy = false,
    opts = {
      skip_confirm_for_simple_edits = true,
      delete_to_trash = false,
      trash_command = "trash",
      -- view_options = {
      --   -- Show files and directories that start with "."
      --   show_hidden = true,
      -- },
    },
    keys = {
      {
        "-",
        function() return require("oil").open() end,
        desc = "Open parent directory",
      },
    },
  },
  -- { import = "astrocommunity.completion.codeium-nvim" },
  { import = "astrocommunity.completion.codeium-vim" },
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  { import = "astrocommunity.recipes.telescope-lsp-mappings" },
  -- import/override with your plugins folder
  {
    "Exafunction/codeium.vim",
    enabled = true,
    version = "1.8.37",
    event = "InsertEnter",
    config = function()
      vim.keymap.set("i", "<C-g>", function() return vim.fn["codeium#Accept"]() end, { expr = true, silent = true })
    end,
  },
}
