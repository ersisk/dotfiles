return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics_mode = 3, -- diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = on)
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = false,
      underline = true,
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "auto", -- sets vim.opt.signcolumn to auto
        wrap = false, -- sets vim.opt.wrap
        conceallevel = 1,
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
        neovide_transparency = 0.1,
        neovide_window_blurred = true,
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs with `H` and `L`
        L = {
          function() require("astrocore.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
          desc = "Next buffer",
        },
        H = {
          function() require("astrocore.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
          desc = "Previous buffer",
        },
        ["<leader>lt"] = { desc = "󰽛 Format & Preview Tools" },
        ["<leader>ltj"] = { "<cmd>%!jq .<cr>", desc = "Format json" },
        ["<leader>ltm"] = { "<cmd>%!jq -c .<cr>", desc = "Minify json" },
        ["<leader>ltf"] = { "<cmd>!docker compose exec app ./vendor/bin/pint<cr>", desc = "Format project with Pint" },
        ["<leader>ltF"] = {
          "<cmd>!docker-compose exec app ./vendor/bin/pint %:.<cr>",
          desc = "Format Buffer with Pint",
        },
        ["<leader>ltg"] = { "<CMD>Glow<CR>", desc = "MarkdownPreview" },
        ["+"] = { "<C-a>", desc = "Increment" },
        ["^"] = { "<C-x>", desc = "Decrement" },
        ["grR"] = {
          "<cmd>lua require('telescope.builtin').lsp_references({})<cr>",
          desc = "Lsp Buf References",
        },
      },
      i = {
        ["<C-s>"] = { "<esc>:w!<cr>", desc = "Save File" }, -- change description but the same command
      },
      t = {
        -- setting a mapping to false will disable it
        -- ["<esc>"] = false,
      },
    },
  },
}
