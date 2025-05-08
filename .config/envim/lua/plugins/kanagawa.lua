return {
	"rebelot/kanagawa.nvim",
	name = "kanagawa",
	priority = 1000, -- Make sure to load this before all the other start plugins.
	enabled = true,
	dependencies = {
		{
			"cormacrelf/dark-notify",
			init = function()
				require("dark_notify").run()
				vim.api.nvim_create_autocmd("OptionSet", {
					pattern = "background",
					callback = function()
						vim.cmd("Kanagawa " .. (vim.v.option_new == "light" and "kanagawa_light" or "kanagawa_dark"))
					end,
				})
			end,
		},
	},

	init = function()
		vim.cmd.colorscheme("kanagawa")
	end,

	---@class KanagawaOptions
	opts = function()
		return {
			transparent = true,
		}
	end,
}
