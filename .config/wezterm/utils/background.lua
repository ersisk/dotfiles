local M = {}
local h = require("utils/helpers")

M.get_background = function()
	return {
		source = {
			Gradient = {
				colors = { h.is_dark() and "#1F1F28" or "#ffffff" },
			},
		},
		width = "100%",
		height = "100%",
		opacity = h.is_dark() and 0.92 or 0.8,
	}
end

return M
