return {
  { "EmranMR/tree-sitter-blade", lazy = false },
  { "ekalinin/Dockerfile.vim", event = "VeryLazy" },
  { "mg979/vim-visual-multi", event = "VeryLazy", enabled = true },
  { "christoomey/vim-tmux-navigator", lazy = false },
  {
    url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    ft = { "python", "php" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
      "williamboman/mason.nvim",
    },
    events = { "BufReadPre", "BufNewFile" },
    config = function()
      local sonar_language_server_path =
        require("mason-registry").get_package("sonarlint-language-server"):get_install_path()
      local analyzers_path = sonar_language_server_path .. "/extension/analyzers"
      require("sonarlint").setup {
        server = {
          cmd = {
            sonar_language_server_path .. "/sonarlint-language-server",
            "-stdio",
            "-analyzers",
            -- paths to the analyzers you need, using those for python and java in this example
            vim.fn.expand(analyzers_path .. "/sonarjava.jar"),
            vim.fn.expand(analyzers_path .. "/sonarpython.jar"),
            vim.fn.expand(analyzers_path .. "/sonarphp.jar"),
          },
        },
        filetypes = {
          "python",
          "php",
        },
      }
    end,
  },
}
