local wezterm = require("wezterm")

local keys = require("keys")
-- local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- config.default_prog = { "/home/kelp/.cargo/bin/nu" }
config.default_prog = { wezterm.home_dir .. "/.cargo/bin/nu" }

--- font settings ---
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
-- config.font = wezterm.font("JetBrainsMono NF")

config.font_size = 16

config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Batman"
--
-- Optional: disable bold as bright
config.bold_brightens_ansi_colors = false

config.front_end = "OpenGL"

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
-- config.use_fancy_tab_bar = true

config.leader = { key = "a", mods = "CTRL" }
-- tabline.apply_to_config(config)
config.keys = keys

-- max screen on startup
wezterm.on("gui-startup", function(cmd)
	local active = wezterm.gui.screens().active
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:guiwindow():setposition(active.x, active.y)
	window:guiwindow():set_innersize(active.width, active.height)
end)

return config
