--if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        lua = { "selene" },
        php = { "php" },
        javascript = { "eslint" },
        typescript = { "eslint" },
      },
    },
  },
}
