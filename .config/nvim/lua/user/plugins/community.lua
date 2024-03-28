return {
  -- Add the community repository of plugin specifications
  "AstroNvim/astrocommunity",
  -- example of imporing a plugin, comment out to use it or add your own
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  { import = "astrocommunity.bars-and-lines.heirline-vscode-winbar" },
  { import = "astrocommunity.bars-and-lines.smartcolumn-nvim" },
  {
    "m4xshen/smartcolumn.nvim",
    opts = {
      colorcolumn = "118",
    },
  },
  {
    "rest.nvim",
    config = function() end,
  },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.colorscheme.onedarkpro-nvim" },
  { import = "astrocommunity.colorscheme.gruvbox-nvim" },
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  { import = "astrocommunity.programming-language-support.rest-nvim" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.docker" },
  { import = "astrocommunity.markdown-and-latex.glow-nvim" },
  { import = "astrocommunity.motion.vim-matchup" },
  { import = "astrocommunity.motion.harpoon" },
  { import = "astrocommunity.lsp.lsp-signature-nvim", enabled = true },
  { import = "astrocommunity.editing-support.cloak-nvim" },
  { import = "astrocommunity.file-explorer.oil-nvim" },
  {
    "oil.nvim",
    opts = {
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
      },
    },
    keys = {
      {
        "-",
        function() return require("oil").open() end,
        desc = "Open parent directory",
      },
    },
  },
  { import = "astrocommunity.completion.codeium-vim" },
}
