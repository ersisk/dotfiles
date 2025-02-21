return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        --lua = { "selene" },
      },
      linters = {
        --selene = { condition = function(ctx) return selene_configured(ctx.filename) end },
      },
    },
  },
}
