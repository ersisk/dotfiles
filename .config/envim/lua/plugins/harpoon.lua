return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			{
				"catppuccin",
				optional = true,
				---@type CatppuccinOptions
				opts = { integrations = { harpoon = true } },
			},
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
				"<C-n>",
				function()
					require("harpoon"):list():next()
				end,
				desc = "Goto next mark",
			},
		},
	},
}
