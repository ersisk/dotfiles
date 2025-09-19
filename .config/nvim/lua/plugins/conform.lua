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
      go = { "gofmt" },
      php = function(bufnr)
        if require("conform").get_formatter_info("pint", bufnr).available then
          return { "pint" }
        else
          return { "php_cs_fixer" }
        end
      end,
    },
    formatters = {
      -- pint = {
      --   command = "pint",
      --   args = { "$FILENAME", "--preset", "psr12", "--parallel" },
      --   stdin = true,
      --   cwd = require("conform.util").root_file { "pint.json" },
      --   require_cwd = false,
      -- },
      -- php_cs_fixer = {
      --   command = "php-cs-fixer",
      --   args = {
      --     "fix",
      --     "$FILENAME",
      --   },
      --   stdin = false,
      --   cwd = require("conform.util").root_file {
      --     "coding_standards/.php-cs-fixer.php",
      --     ".php-cs-fixer.dist.php",
      --     ".php-cs-fixer.php",
      --   },
      --   require_cwd = true,
      -- },
      -- prettierd = {
      --   command = "prettierd",
      --   stdin = true,
      -- },
    },
  },
}
