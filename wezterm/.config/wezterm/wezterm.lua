local wezterm = require("wezterm")
local config = wezterm.config_builder()
-- local action = wezterm.action
local keys_custom = require("keys")
local tabs = require("tabs")
local colors = require("colors")

-- Native Wayland (the default). XWayland was forced here for the old NVIDIA
-- card, but it broke clipboard sync with native Wayland apps. The AMD 6700 XT
-- drives native Wayland fine, so the override and the XWayland cursor
-- workarounds are gone.

-- Default WebGpu front-end. OpenGL was forced for the NVIDIA proprietary
-- driver (compositor freeze 2026-06-02). AMD 6700 XT + Mesa handles WebGpu.
-- Re-add `config.front_end = "OpenGL"` if rendering glitches appear.

-- Reason: cap per-pane scrollback so a long-lived session can't grow unbounded.
config.scrollback_lines = 5000

-- Reason: nu install location varies by machine (cargo, ~/.local/bin, or
-- system package). Probe candidates in priority order and use the first hit.
local nu_candidates = {
	wezterm.home_dir .. "/.cargo/bin/nu",
	wezterm.home_dir .. "/.local/bin/nu",
	"/usr/local/bin/nu",
	"/usr/bin/nu",
}
local nu_path = "nu" -- fallback: rely on PATH lookup
for _, candidate in ipairs(nu_candidates) do
	local f = io.open(candidate, "r")
	if f then
		f:close()
		nu_path = candidate
		break
	end
end
config.default_prog = { nu_path }

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
config.color_schemes = colors.color_schemes
config.color_scheme = colors.color_scheme
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.window_padding = { left = "0.5cell", right = "0.5cell", top = "0.5cell", bottom = "0.5cell" }
-- Opaque background; no alpha blending needed.
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
