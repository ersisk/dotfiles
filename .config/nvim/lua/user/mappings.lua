-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    -- mappings seen under group name "Buffer"
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr) require("astronvim.utils.buffer").close(bufnr) end
        )
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    ["<leader>lF"] = { "<cmd>!docker-compose exec app ./vendor/bin/pint<cr>", desc = "Format project with Pint" },
    ["<leader>rP"] = { "<cmd>!docker-compose exec app ./vendor/bin/pint %:.<cr>", desc = "Format Buffer with Pint" },

    ---CodeRunner
    ["<leader>r"] = { desc = "󰐍 Code runner" },
    ["<leader>re"] = { "<CMD>RunCode<CR>", desc = "Run code" },
    ["<leader>rf"] = { "<CMD>RunFile<CR>", desc = "Run file" },
    ["<leader>rt"] = { "<CMD>RunFile tab<CR>", desc = "Run file tab" },
    ["<leader>rc"] = { "<CMD>RunClose<CR>", desc = "Close runner" },
    ["<leader>rp"] = { "<CMD>RunFile toggleterm<CR>", desc = "Run file pop up (toggleterm)" },

    --- Markdown Preview
    ["<leader>m"] = { desc = "󰽛 Markdown" },
    ["<leader>mm"] = { "<CMD>Glow<CR>", desc = "MarkdownPreview" },
    ["<leader>rjf"] = { "<cmd>%!jq .<cr>", desc = "Format json" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
}
