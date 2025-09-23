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
    format_on_save = function(bufnr)
      -- Disable autoformat on certain filetypes
      local ignore_filetypes = { "blade" }
      if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then return end
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      -- Disable autoformat for files in a certain path
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname:match "/node_modules/" then return end
      -- ...additional logic...
      return { timeout_ms = 500, lsp_format = "fallback" }
    end,
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
