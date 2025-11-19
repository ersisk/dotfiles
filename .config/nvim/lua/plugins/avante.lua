return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  opts = {
    provider = "copilot", -- Recommend using Claude
    auto_suggestions_provider = "copilot",
    providers = {
      copilot = {
        model = "claude-haiku-4.5",
      },
    },
  },
}
