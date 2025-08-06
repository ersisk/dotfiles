return {
	"rebelot/kanagawa.nvim",
	name = "kanagawa",
	priority = 1000, -- Make sure to load this before all the other start plugins.
	enabled = true,
	dependencies = {},

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
