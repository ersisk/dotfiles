local b = require("utils/background")
local cs = require("utils/color_scheme")
local f = require("utils/font")
local k = require("utils/keys")
-- local w = require("utils/wallpaper")

local wezterm = require("wezterm")
local act = wezterm.action

local config = {
	-- background
	background = {
		--w.get_wallpaper(),
		b.get_background(),
	},

	-- font
	font = f.get_font(),
	font_size = 19,

	-- colors
	color_scheme = cs.get_color_scheme(),
	-- padding
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = "0.1cell",
	},

	-- general options
	adjust_window_size_when_changing_font_size = false,
	debug_key_events = false,
	enable_tab_bar = false,
	enable_scroll_bar = false,

	native_macos_fullscreen_mode = false,
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE",
	window_background_opacity = 0.65,

	-- keys
	keys = {
		k.cmd_to_tmux_prefix("1", "1"),
		k.cmd_to_tmux_prefix("2", "2"),
		k.cmd_to_tmux_prefix("3", "3"),
		k.cmd_to_tmux_prefix("4", "4"),
		k.cmd_to_tmux_prefix("5", "5"),
		k.cmd_to_tmux_prefix("6", "6"),
		k.cmd_to_tmux_prefix("7", "7"),
		k.cmd_to_tmux_prefix("8", "8"),
		k.cmd_to_tmux_prefix("9", "9"),
		k.cmd_to_tmux_prefix("C", "C"),
		k.cmd_to_tmux_prefix("d", "D"),
		k.cmd_to_tmux_prefix("E", "%"),
		k.cmd_to_tmux_prefix('"', '"'),
		k.cmd_to_tmux_prefix("k", "T"),
		k.cmd_to_tmux_prefix("l", "L"),
		k.cmd_to_tmux_prefix("t", "c"),
		k.cmd_to_tmux_prefix("ş", "ş"),
		k.cmd_to_tmux_prefix("ğ", ","),
		k.cmd_to_tmux_prefix("Ğ", "$"),
		k.cmd_to_tmux_prefix("w", "&"),
		k.cmd_to_tmux_prefix("W", "x"),
		k.cmd_to_tmux_prefix("g", "g"),
		k.cmd_key("O", k.multiple_actions(":GoToSymbol")),
		k.cmd_key("P", k.multiple_actions(":GoToCommand")),
		k.cmd_key("p", k.multiple_actions(":GoToFile")),
		k.cmd_key("T", k.multiple_actions(":GoToBuffer")),
		k.cmd_key(
			"K",
			act.Multiple({
				act.SendKey({ key = "t" }),
				act.SendKey({ key = "s" }),
				act.SendKey({ key = "\x0a" }),
			})
		),

		k.cmd_key(
			"s",
			act.Multiple({
				act.SendKey({ key = "\x1b" }), -- escape
				k.multiple_actions(":w"),
			})
		),
		{
			mods = "CTRL",
			key = "Tab",
			action = act.Multiple({
				act.SendKey({ mods = "CTRL", key = "a" }),
				act.SendKey({ key = "n" }),
			}),
		},
		{
			mods = "CMD",
			key = "~",
			action = act.Multiple({
				act.SendKey({ mods = "CTRL", key = "a" }),
				act.SendKey({ key = "p" }),
			}),
		},
	},
}

return config
