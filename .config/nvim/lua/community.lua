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
  { import = "astrocommunity.pack.go" },
  --ui
  { import = "astrocommunity.recipes.ai" },
  { import = "astrocommunity.recipes.heirline-vscode-winbar" },
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.colorscheme.kanagawa-nvim" },
  --markdown
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
  --motion
  { import = "astrocommunity.motion.vim-matchup" },
  --file explorer
  { import = "astrocommunity.file-explorer.oil-nvim" },
  --Copilot
  { import = "astrocommunity.completion.copilot-lua" },
  { import = "astrocommunity.completion.avante-nvim" },
  { import = "astrocommunity.programming-language-support.kulala-nvim" },
  -- Visual Multi
  { import = "astrocommunity.editing-support.vim-visual-multi" },
  -- Note
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  --Motion
  { import = "astrocommunity.motion.harpoon" },
}
