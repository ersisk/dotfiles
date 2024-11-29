-- Customize Mason plugins

---@type LazySpec
return {
  -- use mason-lspconfig to configure LSP installations
  {
    "williamboman/mason-lspconfig.nvim",
    -- overrides `require("mason-lspconfig").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "lua_ls",
        "tsserver",
        "intelephense",
        "gopls",
        "pyright",
        "eslint",
        -- add more arguments for adding more language servers
      })
    end,
  },
  -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources
  {
    "jay-babu/mason-null-ls.nvim",
    -- overrides `require("mason-null-ls").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "stylua",
        "pint",
        "gofumpt",
        "iferr",
        "impl",
        "black",
        "isort",
        "selene",
        -- add more arguments for adding more null-ls sources
      })

      opts.automatic_setup = true
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- overrides `require("mason-nvim-dap").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "python",
        "go",
        -- add more arguments for adding more debuggers
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "AstroNvim/astrolsp", opts = {} },
      {
        "williamboman/mason-lspconfig.nvim", -- MUST be set up before `nvim-lspconfig`
        dependencies = { "williamboman/mason.nvim" },
        opts = function()
          return {
            -- use AstroLSP setup for mason-lspconfig
            handlers = { function(server) require("astrolsp").lsp_setup(server) end },
          }
        end,
      },
    },
    config = function()
      -- set up servers configured with AstroLSP
      vim.tbl_map(require("astrolsp").lsp_setup, require("astrolsp").config.servers)
    end,
  },
}
