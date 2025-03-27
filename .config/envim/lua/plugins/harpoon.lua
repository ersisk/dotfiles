return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		keys = {
			{
				"<leader><leader>e",
				function()
					require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
				end,
				desc = "Toggle Harpoon",
			},
			{
				"<leader><leader>a",
				function()
					require("harpoon"):list():add()
				end,
				desc = "Add file to Harpoon",
			},
			{
				"<C-p>",
				function()
					require("harpoon"):list():prev()
				end,
				desc = "Goto previous mark",
			},
			{
				"<C-b>",
				function()
					require("harpoon"):list():next()
				end,
				desc = "Goto next mark",
			},
			{
				"<C-x>",
				function()
					vim.ui.input({ prompt = "Harpoon mark index: " }, function(input)
						local num = tonumber(input)
						if num then
							require("harpoon"):list():select(num)
						end
					end)
				end,
				desc = "Select mark index",
			},
		},
	},
}
