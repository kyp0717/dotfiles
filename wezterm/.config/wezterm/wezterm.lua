local wezterm = require("wezterm")

local keys = require("keys")
-- local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.default_prog = { "/home/kelp/.cargo/bin/nu" }

--- font settings ---
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
-- tabline.apply_to_config(config)
config.keys = keys

return config
