return {
  "nvimtools/none-ls.nvim",
  opts = function(_, config)
    -- config variable is the default configuration table for the setup function call
    local null_ls = require "null-ls"

    -- Check supported formatters and linters
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
    config.sources = {
      -- Set a formatter
      null_ls.builtins.diagnostics.eslint,
      null_ls.builtins.formatting.blade_formatter,
      -- null_ls.builtins.formatting.stylua,
      -- null_ls.builtins.formatting.prettier,
      -- null_ls.builtins.formatting.rufo,
      --[[  null_ls.builtins.formatting.phpcsfixer.with{
        extra_args = {
           "--rules=@Symfony",
            "--using-cache=no",
            "--no-interaction",
            "fix",
        }
      }, ]]
      -- null_ls.builtins.formatting.gofmt,
      --[[ null_ls.builtins.formatting.prettier,
      null_ls.builtins.formatting.fprettify, ]]
      -- null_ls.builtins.diagnostics.rubocop,
    }
    return config -- return final config table
  end,
}
