-- Customize Mason plugins
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- install language servers
        "lua-language-server",
        "intelephense",
        "gopls",

        -- install formatters
        "stylua",
        "pint",
        { "php-cs-fixer", filetype = "php" },
        "gofumpt",
        "iferr",
        "impl",
        "black",
        "isort",

        -- install debuggers
        "debugpy",

        -- install any other package
        "tree-sitter-cli",
      },
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = {
      handlers = {
        phpcsfixer = function()
          require("null-ls").register(require("null-ls").builtins.formatting.phpcsfixer.with {
            condition = function(utils)
              return utils.root_has_file "coding_standards/.php-cs-fixer.php"
                or utils.root_has_file ".php-cs-fixer.dist.php"
                or utils.root_has_file ".php-cs-fixer.php"
            end,
            -- TODO: extra_args not working as expected, needs debugging
            -- extra_args = function(params)
            --   local files = {
            --     "coding_standards/.php-cs-fixer.php",
            --     ".php-cs-fixer.dist.php",
            --     ".php-cs-fixer.php",
            --   }
            --   local root_dir = params.root
            --   for _, file in ipairs(files) do
            --     local path = root_dir .. "/" .. file
            --     print("Checking for config file at: " .. path)
            --     if vim.fn.filereadable(path) == 1 then return { "--config=", path } end
            --   end
            --   return {}
            -- end,
          })
        end,
        pint = function()
          require("null-ls").register(require("null-ls").builtins.formatting.pint.with {
            condition = function(utils) return utils.root_has_file "pint.json" or utils.root_has_file ".pint" end,
          })
        end,
      },
    },
  },
}
