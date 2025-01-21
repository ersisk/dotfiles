-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  --
  -- packs
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.docker" },
  { import = "astrocommunity.pack.typescript-all-in-one" },
  { import = "astrocommunity.pack.blade" },
  --ui
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.colorscheme.onedarkpro-nvim" },
  { import = "astrocommunity.colorscheme.dracula-nvim" },
  --markdown
  { import = "astrocommunity.markdown-and-latex.glow-nvim" },
  --motion
  { import = "astrocommunity.motion.vim-matchup" },
  { import = "astrocommunity.motion.harpoon" },
  --lsp
  { import = "astrocommunity.lsp.lsp-signature-nvim", enabled = true },
  { import = "astrocommunity.lsp.nvim-lint", enabled = true },
  --file explorer
  { import = "astrocommunity.file-explorer.oil-nvim" },

  --Copilot
  -- { import = "astrocommunity.completion.codeium-nvim" },
  -- { import = "astrocommunity.completion.codeium-vim" },
  { import = "astrocommunity.completion.copilot-cmp" },
  { import = "astrocommunity.editing-support.copilotchat-nvim" },
  -- Note
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  --Keymap
  { import = "astrocommunity.recipes.telescope-lsp-mappings" },
  { import = "astrocommunity.recipes.neovide" },
  --git
  { import = "astrocommunity.git.diffview-nvim" },
  -- import/override with your plugins folder
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
