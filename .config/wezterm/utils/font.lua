local wezterm = require("wezterm")
local h = require("utils/helpers")
local M = {}

M.get_font = function()
	local fonts = {
		"JetBrainsMono NFM",
	}
	local family = h.get_random_entry(fonts)
	return wezterm.font_with_fallback({ { family = family, weight = "Bold" }, { family = "JetBrainsMono NFM" } })
end

return M
