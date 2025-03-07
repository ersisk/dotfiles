--[[
██╗  ██╗███████╗██╗   ██╗███╗   ███╗ █████╗ ██████╗ ███████╗
██║ ██╔╝██╔════╝╚██╗ ██╔╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
█████╔╝ █████╗   ╚████╔╝ ██╔████╔██║███████║██████╔╝███████╗
██╔═██╗ ██╔══╝    ╚██╔╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ███████║
╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝
--]]

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>")
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- clipboard
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to clipboard" })

vim.keymap.set("n", "<Tab>", "<cmd>bn<cr>")
vim.keymap.set("n", "<S-Tab>", "<cmd>bp<cr>")

vim.keymap.set("n", "*", "*zz")

vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- folds
--vim.keymap.set("n", "<leader>z", "<cmd>normal! zMzv<cr>", { desc = "Fold all others" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
local function mason_notify(msg, type)
	require("noice").notify(msg, type)
end
vim.keymap.set("n", "<leader>pa", function()
	require("lazy").sync()
	local registry_avail, registry = pcall(require, "mason-registry")
	if not registry_avail then
		vim.api.nvim_err_writeln("Unable to access mason registry")
		return
	end

	mason_notify("Checking for package updates...")
	registry.update(vim.schedule_wrap(function(success, updated_registries)
		if success then
			local installed_pkgs = registry.get_installed_packages()
			local running = #installed_pkgs
			local no_pkgs = running == 0

			if no_pkgs then
				mason_notify("No updates available")
			else
				local updated = false
				for _, pkg in ipairs(installed_pkgs) do
					pkg:check_new_version(function(update_available, version)
						if update_available then
							updated = true
							mason_notify(("Updating `%s` to %s"):format(pkg.name, version.latest_version))
							pkg:install():on("closed", function()
								running = running - 1
								if running == 0 then
									mason_notify("Update Complete")
								end
							end)
						else
							running = running - 1
							if running == 0 then
								if updated then
									mason_notify("Update Complete")
								else
									mason_notify("No updates available")
								end
							end
						end
					end)
				end
			end
		else
			mason_notify(("Failed to update registries: %s"):format(updated_registries), vim.log.levels.ERROR)
		end
	end))
end, { desc = "Update packages" })
