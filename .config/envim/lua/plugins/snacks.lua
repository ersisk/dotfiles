return {
	"folke/snacks.nvim",
	enabled = true,
	lazy = false,
	---@type snacks.Config
	opts = {
		picker = { enabled = true },
		notifier = { enabled = true },
		input = { enabled = true },
		bigfile = { enabled = true },
		zen = {
			---@type table<string, boolean>
			toggles = {
				dim = false,
				git_signs = false,
				mini_diff_signs = false,
				diagnostics = false,
				inlay_hints = false,
			},
			---@type table<string, boolean>
			show = {
				statusline = false,
				tabline = false,
			},
			---@type snacks.win.Config
			win = { style = "zen", relative = "editor" },
			zoom = {
				toggles = {},
				show = { statusline = true, tabline = true },
				win = {
					backdrop = false,
					-- width = 0, -- full width
				},
			},
		},
	},
	keys = {
		{
			"<leader>fw",
			function()
				---@diagnostic disable-next-line: missing-fields
				Snacks.picker.grep({
					hidden = true,
				})
			end,
			desc = "Grep",
		},
		-- {
		-- 	"<leader>/",
		-- 	function()
		-- 		Snacks.picker.command_history()
		-- 	end,
		-- 	desc = "Command History",
		-- },
		-- find
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>fc",
			function()
				---@diagnostic disable-next-line: missing-fields
				Snacks.picker.files({ cwd = print(vim.fn.stdpath("config")) })
			end,
			desc = "Find Config File",
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>fg",
			function()
				Snacks.picker.git_files()
			end,
			desc = "Find Git Files",
		},
		-- {
		-- 	"<leader>fr",
		-- 	function()
		-- 		Snacks.picker.recent()
		-- 	end,
		-- 	desc = "Recent",
		-- },
		-- git
		{
			"<leader>gl",
			function()
				Snacks.picker.git_log()
			end,
			desc = "[g]it [l]og",
		},
		{
			"<leader>gs",
			function()
				Snacks.picker.git_status()
			end,
			desc = "Git Status",
		},
		-- Grep
		{
			"<leader>f/",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Grep Open Buffers",
		},
		{
			"<leader>fW",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Visual selection or word",
			mode = { "n", "x" },
		},
		{
			"<leader>fC",
			function()
				Snacks.picker.commands()
			end,
			desc = "Commands",
		},
		{
			"<leader>fd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Diagnostics",
		},
		{
			"<leader>fh",
			function()
				Snacks.picker.help()
			end,
			desc = "Help Pages",
		},
		{
			"<leader>fH",
			function()
				Snacks.picker.highlights()
			end,
			desc = "Highlights",
		},
		{
			"<leader>fj",
			function()
				Snacks.picker.jumps()
			end,
			desc = "Jumps",
		},
		{
			"<leader>fk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "Keymaps",
		},
		{
			"<leader>fl",
			function()
				Snacks.picker.loclist()
			end,
			desc = "Location List",
		},
		{
			"<leader>fM",
			function()
				Snacks.picker.man()
			end,
			desc = "Man Pages",
		},
		{
			"<leader>f'",
			function()
				Snacks.picker.marks()
			end,
			desc = "Marks",
		},
		{
			"<leader>fR",
			function()
				Snacks.picker.resume()
			end,
			desc = "Resume",
		},
		{
			"<leader>fq",
			function()
				Snacks.picker.qflist()
			end,
			desc = "Quickfix List",
		},
		-- {
		-- 	"<leader>uC",
		-- 	function()
		-- 		Snacks.picker.colorschemes()
		-- 	end,
		-- 	desc = "Colorschemes",
		-- },
		{
			"<leader>fp",
			function()
				Snacks.picker.projects()
			end,
			desc = "Projects",
		},
		-- LSP
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Goto Definition",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			nowait = true,
			desc = "References",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Goto Implementation",
		},
		{
			"gy",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "Goto T[y]pe Definition",
		},
		{
			"<leader>fs",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
	},
}
