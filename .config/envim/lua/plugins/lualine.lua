return {
	"nvim-lualine/lualine.nvim",
	-- TODO: ensure this is correct name
	dependencies = {
		{ "folke/trouble.nvim" },
		-- { 'bezhermoso/todos-lualine.nvim' },
		-- { 'folke/todo-comments.nvim' },
	},
	enabled = true,
	event = "VeryLazy",
	opts = function(plugin)
		if plugin.override then
			require("lazyvim.util").deprecate("lualine.override", "lualine.opts")
		end
		-- local icons = require 'config.icons'
		local lspIcons = require("utils.icons").lsp

		local diagnostics = {
			"diagnostics",
			sources = { "nvim_diagnostic" },
			sections = { "error", "warn", "info", "hint" },
			symbols = {
				error = lspIcons.error,
				hint = lspIcons.hint,
				info = lspIcons.info,
				warn = lspIcons.warn,
			},
			colored = true,
			update_in_insert = false,
			always_visible = false,
		}

		local diff = {
			"diff",
			symbols = {
				added = " ",
				untracked = "󱀶 ",
				modified = " ",
				removed = " ",
			},
			colored = true,
			always_visible = false,
			source = function()
				local gitsigns = vim.b.gitsigns_status_dict
				if gitsigns then
					return {
						added = gitsigns.added,
						modified = gitsigns.changed,
						removed = gitsigns.removed,
					}
				end
			end,
		}

		local mode = {
			"mode",
			separator = { left = "" },
			right_padding = 1,
			fmt = function()
				local mode = vim.fn.mode()
				local mode_map = {
					n = "N",
					i = "I",
					c = "C",
					V = "V",
					[""] = "V",
					v = "V",
					R = "R",
					t = "T",
				}
				return mode_map[mode]
			end,
			colored = true,
		}

		local function show_macro_recording()
			local recording_register = vim.fn.reg_recording()
			if recording_register == "" then
				return ""
			else
				return "Recording @" .. recording_register
			end
		end

		return {
			options = {
				theme = "auto",
				globalstatus = true,
				disabled_filetypes = { statusline = { "dashboard", "lazy", "alpha" } },
				section_separators = { left = "", right = "" },
				component_separators = { left = "", right = "" },
			},
			tabline = {
				lualine_a = { mode },
				lualine_b = {},
				lualine_c = {
					{
						"filename",
						file_status = true, -- Displays file status (readonly status, modified status)
						newfile_status = false, -- Display new file status (new file means no write after created)
						-- 0: Just the filename
						-- 1: Relative path
						-- 2: Absolute path
						-- 3: Absolute path, with tilde as the home directory
						-- 4: Filename and parent dir, with tilde as the home directory
						path = 1,

						-- shorting_target = 40,
						symbols = {
							modified = "[+]", -- Text to show when the file is modified.
							readonly = "🔒", -- Text to show when the file is non-modifiable or readonly.
							unnamed = "[No Name]", -- Text to show for unnamed buffers.
							newfile = "[New]", -- Text to show for newly created file before first write
						},
					},
					diff,
					diagnostics,
				},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {
					{
						"branch",
						icon = "",
						color = { gui = "bold" },
					},
				},
			},
			sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "macro-recording", fmt = show_macro_recording } },
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
		}
	end,
}
