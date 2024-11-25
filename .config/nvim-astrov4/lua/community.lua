-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.docker" },
  { import = "astrocommunity.pack.typescript-all-in-one" },
  { import = "astrocommunity.pack.blade" },
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.colorscheme.onedarkpro-nvim" },
  --{ import = "astrocommunity.programming-language-support.rest-nvim" },
  { import = "astrocommunity.markdown-and-latex.glow-nvim" },
  { import = "astrocommunity.motion.vim-matchup" },
  { import = "astrocommunity.motion.harpoon" },
  { import = "astrocommunity.lsp.lsp-signature-nvim", enabled = true },
  { import = "astrocommunity.lsp.nvim-lint", enabled = true },
  { import = "astrocommunity.file-explorer.oil-nvim" },
  -- { import = "astrocommunity.completion.codeium-nvim" },
  -- { import = "astrocommunity.completion.codeium-vim" },
  { import = "astrocommunity.completion.copilot-cmp" },
  { import = "astrocommunity.editing-support.copilotchat-nvim" },
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  { import = "astrocommunity.recipes.telescope-lsp-mappings" },
  { import = "astrocommunity.recipes.heirline-nvchad-statusline" },
  -- import/override with your plugins folder
  {
    "m4xshen/smartcolumn.nvim",
    opts = {
      colorcolumn = "118",
    },
  },
  -- {
  --   "Exafunction/codeium.vim",
  --   enabled = true,
  --   version = "1.8.37",
  --   event = "InsertEnter",
  --   config = function()
  --     vim.keymap.set("i", "<C-g>", function() return vim.fn["codeium#Accept"]() end, { expr = true, silent = true })
  --   end,
  -- },
}
