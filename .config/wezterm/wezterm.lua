local b = require("utils/background")
local f = require("utils/font")
local k = require("utils/keys")
local w = require("utils/wallpaper")

local wezterm = require("wezterm")
local act = wezterm.action

local config = {
	-- background
	background = {
		w.get_wallpaper(),
		b.get_background(),
	},
	-- font
	font = f.get_font(),
	font_size = 19,

	-- colors
	color_scheme = "Kanagawa (Gogh)",
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
	--window_background_opacity = 0.65,

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
		-- Detach Session
		k.cmd_to_tmux_prefix("d", "D"),
		-- Vertical Split
		k.cmd_to_tmux_prefix("n", "%"),
		-- Horizontal Split
		k.cmd_to_tmux_prefix('"', '"'),
		-- Sesh
		k.cmd_to_tmux_prefix("k", "T"),
		-- Last Session
		k.cmd_to_tmux_prefix("l", "L"),
		-- New Window
		k.cmd_to_tmux_prefix("t", "c"),
		-- Toogle Tmux Status
		k.cmd_to_tmux_prefix("B", "b"),
		k.cmd_to_tmux_prefix("C", "["),
		-- Rename Window
		k.cmd_to_tmux_prefix("ğ", ","),
		-- Rename Session
		k.cmd_to_tmux_prefix("R", "$"),
		k.cmd_to_tmux_prefix("w", "&"),
		k.cmd_to_tmux_prefix("W", "x"),
		-- LazyGit
		k.cmd_to_tmux_prefix("g", "g"),
		--LazySql
		k.cmd_to_tmux_prefix("M", "m"),
		-- OpenURL
		k.cmd_to_tmux_prefix("o", "u"),
		-- Navigate Panes
		k.cmd_to_tmux_prefix("LeftArrow", "p"),
		k.cmd_to_tmux_prefix("RightArrow", "n"),
		-- Opencode
		k.cmd_to_tmux_prefix("a", "a"),
		--Claude
		k.cmd_to_tmux_prefix("A", "A"),
		-- Copilot
		k.cmd_to_tmux_prefix("z", "Z"),
		--GH DASH
		k.cmd_to_tmux_prefix("G", "z"),
		-- Telescope-like actions
		k.cmd_key("P", k.multiple_actions(":GoToSymbol")),
		k.cmd_key("p", k.multiple_actions(":GoToFile")),
		k.cmd_key("T", k.multiple_actions(":GoToBuffer")),
		-- Save file
		k.cmd_key(
			"s",
			act.Multiple({
				act.SendKey({ key = "\x1b" }), -- escape
				k.multiple_actions(":w"),
			})
		),
	},
}

return config
