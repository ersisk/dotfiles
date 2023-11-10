return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "lua",
      "tsx",
      "html",
      "css",
      "php",
      "python",
      "go",
      "javascript",
      "json",
      "phpdoc",
    },
    indent = {
      enable = true,
    },
    highlight = {
      enable = true,
    },
    autotag = {
      enable = true,
    },
  },
}
