return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      json = { "prettierd" },
      html = { "prettierd" },
      css = { "prettierd" },
      scss = { "prettierd" },
      markdown = { "prettierd" },
      yaml = { "prettierd" },
      toml = { "taplo" },
      sh = { "shfmt" },
      php = function() return { "pint", "php_cs_fixer" } end,
    },
    format_on_save = {
      timeout_ms = 5000,
      lsp_fallback = true,
    },
    formatters = {
      pint = {
        command = "pint",
        args = { "$FILENAME", "--parallel" },
        stdin = true,
        cwd = require("conform.util").root_file { "pint.json" },
        require_cwd = false,
      },
      php_cs_fixer = {
        command = "php-cs-fixer",
        args = {
          "fix",
          "$FILENAME",
        },
        stdin = false,
        cwd = require("conform.util").root_file {
          "coding_standards/.php-cs-fixer.php",
          ".php-cs-fixer.dist.php",
          ".php-cs-fixer.php",
        },
        require_cwd = true,
      },
      prettierd = {
        command = "prettierd",
        stdin = true,
      },
    },
  },
}
