return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  config = function()
    vim.keymap.set("n", "<C-b>", function() require("harpoon"):list():next() end, { desc = "Goto next mark" })
  end,
}
