return {
	"joshuavial/aider.nvim",
	opts = {
		auto_manage_context = true, -- automatically manage buffer context
		default_bindings = false, -- use default <leader>A keybindings
		debug = false, -- enable debug logging
	},
	keys = {
		{ "<leader>Ao", ":AiderOpen<CR>", desc = "Open Aider" },
		{
			"<leader>Am",
			":AiderAddModifiedFiles<CR>",
			desc = "Add Modified Files to Aider",
		},
	},
}
