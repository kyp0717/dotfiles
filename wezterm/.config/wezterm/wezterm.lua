local wezterm = require("wezterm")
local act = wezterm.action
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.default_prog = { "/home/phage/.cargo/bin/nu" }

config.font = wezterm.font("JetBrainsMono Nerd Font Mono")

config.font_size = 16

config.color_scheme = "Catppuccin Mocha"

config.window_background_opacity = 1.0

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

config.window_background_gradient = {
	interpolation = "Linear",

	orientation = "Vertical",

	blend = "Rgb",

	colors = {
		"#11111b",
		"#181825",
	},
}

config.use_fancy_tab_bar = false

config.leader = { key = "a", mods = "CTRL" }
config.keys = {
	{
		key = "h",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "j",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{ key = "K", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
	{
		key = "l",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "r",
		mods = "LEADER",
		action = wezterm.action.ReloadConfiguration,
	},
}

return config
