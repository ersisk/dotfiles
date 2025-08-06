return {
	"olimorris/onedarkpro.nvim",
	name = "onedarkpro",
	priority = 1000, -- Make sure to load this before all the other start plugins.
	enabled = false,
	dependencies = {},

	init = function()
		vim.cmd.colorscheme("onedark")
	end,

	---@class OneDarkProOptions
	opts = function()
		return {
			options = {
				transparency = true,
			},
			integrations = {
				cmp = true,
				blink_cmp = true,
				copilot_vim = true,
				fidget = true,
				gitsigns = true,
				lsp_trouble = true,
				mason = true,
				neotest = true,
				noice = true,
				notify = true,
				octo = true,
				telescope = true,
				treesitter = true,
				treesitter_context = false,
				snacks = true,
				illuminate = true,
				which_key = true,
				native_lsp = {
					enabled = true,
					virtual_text = {
						errors = { "italic" },
						hints = { "italic" },
						warnings = { "italic" },
						information = { "italic" },
					},
					underlines = {
						errors = { "underline" },
						hints = { "underline" },
						warnings = { "underline" },
						information = { "underline" },
					},
				},
			},
		}
	end,
}
