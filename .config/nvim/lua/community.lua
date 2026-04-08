-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.typescript-all-in-one" },
  { import = "astrocommunity.pack.go" },
  --ui
  { import = "astrocommunity.recipes.ai" },
  { import = "astrocommunity.recipes.heirline-vscode-winbar" },
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.colorscheme.kanagawa-nvim" },
  { import = "astrocommunity.recipes.neovide" },
  --motion
  { import = "astrocommunity.motion.vim-matchup" },
  --file explorer
  { import = "astrocommunity.file-explorer.oil-nvim" },
  --Copilot
  { import = "astrocommunity.completion.copilot-lua-cmp" },
  -- API TESTING & TOOLS
  -- { import = "astrocommunity.programming-language-support.kulala-nvim" },
  -- Visual Multi
  { import = "astrocommunity.editing-support.vim-visual-multi" },
  -- Note
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  --Motion
  { import = "astrocommunity.motion.harpoon" },
  { import = "astrocommunity.motion.flash-nvim" },
  -- Formating
  { import = "astrocommunity.editing-support.conform-nvim" },
  { import = "astrocommunity.lsp.nvim-lint" },

  { import = "astrocommunity.terminal-integration.vim-tmux-navigator" },
  { import = "astrocommunity.editing-support.undotree" },

  --- Git
  { import = "astrocommunity.git.codediff-nvim" },

  --- Markdown
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
}
