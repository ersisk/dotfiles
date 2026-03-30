-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true, -- enable/disable treesitter based highlighting
      indent = true, -- enable/disable treesitter based indentation
      auto_install = true, -- enable/disable automatic installation of detected languages
      ensure_installed = {
        "lua",
        "vim",
        "lua",
        "vim",
        "tsx",
        "html",
        "css",
        "php",
        "python",
        "go",
        "javascript",
        "json",
        "phpdoc",
        "markdown",
        "typescript",
        "sql",
        "rust",
        "cpp",

        -- add more arguments for adding more treesitter parsers
      },
    },
  },
}
