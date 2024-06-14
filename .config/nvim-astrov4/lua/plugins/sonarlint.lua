if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
--- Not Work

return {
  {
    url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    ft = { "python", "php" },
    event = { "User AstroLspSetup" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
    },
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
          "java",
          "php",
        },
      }
    end,
  },
}
