local wezterm = require("wezterm")
local config = wezterm.config_builder()
-- local action = wezterm.action
local keys_custom = require("keys")
local tabs = require("tabs")
local colors = require("colors")

-- Disable Wayland to use XWayland
-- wezterm not working on Wayland with nvidia drivers, see
config.enable_wayland = false

-- Set cursor size and theme to fix scaling under XWayland
config.xcursor_size = 32
config.xcursor_theme = "Adwaita"

-- Reason: default WebGpu front-end leaks/locks up on the NVIDIA proprietary
-- driver over XWayland (caused a compositor freeze on 2026-06-02). OpenGL is
-- the stable path for this setup.
config.front_end = "OpenGL"

-- Reason: cap per-pane scrollback so a long-lived session can't grow unbounded.
config.scrollback_lines = 5000

-- config.default_prog = { "/home/kelp/.cargo/bin/nu" }
config.default_prog = { "/usr/bin/nu" }

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Macchiato"
	else
		return "Catppuccin Latte"
	end
end

config.font = wezterm.font({
	family = "JetBrains Mono",
	weight = "Medium",
	harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
})
config.font_size = 15.0
config.line_height = 1.0
config.bold_brightens_ansi_colors = true
-- config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
config.color_scheme = colors.color_scheme
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.window_padding = { left = "0.5cell", right = "0.5cell", top = "0.5cell", bottom = "0.5cell" }
-- Reason: opaque to take alpha-blending load off the NVIDIA/XWayland compositor.
config.window_background_opacity = 1.0
config.macos_window_background_blur = 20
config.default_cursor_style = "BlinkingBar"
config.use_fancy_tab_bar = false
config.leader = { key = "g", mods = "CTRL" }

-- https://github.com/wez/wezterm/issues/3299#issuecomment-2145712082
wezterm.on("gui-startup", function(cmd)
	local active = wezterm.gui.screens().active
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():set_position(active.x, active.y)
	window:gui_window():set_inner_size(active.width, active.height)
end)

config.keys = keys_custom
tabs.apply_to_config(config)

return config
