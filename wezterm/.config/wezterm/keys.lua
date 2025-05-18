local wezterm = require("wezterm")
local action = wezterm.action

return {
	-- Rename tab: Ctrl+Shift+r
	{
		key = "r",
		mods = "CTRL|SHIFT",
		action = action.PromptInputLine({
			description = "Rename Tab",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{
		key = "h",
		mods = "LEADER",
		action = action.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "j",
		mods = "LEADER",
		action = action.AdjustPaneSize({ "Down", 5 }),
	},
	{ key = "K", mods = "LEADER", action = action.AdjustPaneSize({ "Up", 5 }) },
	{
		key = "l",
		mods = "LEADER",
		action = action.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "r",
		mods = "LEADER",
		action = wezterm.action.ReloadConfiguration,
	},
	{ key = "d", mods = "CTRL|SHIFT", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "CTRL", action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "k", mods = "CTRL", action = action.ClearScrollback("ScrollbackAndViewport") },
	{ key = "w", mods = "CTRL", action = action.CloseCurrentPane({ confirm = false }) },
	{ key = "w", mods = "CTRL|SHIFT", action = action.CloseCurrentTab({ confirm = false }) },
	{ key = "LeftArrow", mods = "CTRL", action = action.SendKey({ key = "Home" }) },
	{ key = "RightArrow", mods = "CTRL", action = action.SendKey({ key = "End" }) },
	{ key = "p", mods = "CTRL|SHIFT", action = action.ActivateCommandPalette },
	{
		key = ",",
		mods = "CTRL",
		action = action.SpawnCommandInNewTab({ cwd = wezterm.home_dir, args = { "zed", wezterm.config_file } }),
	},
}
