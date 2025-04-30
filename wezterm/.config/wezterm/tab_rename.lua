local wezterm = require("wezterm")
local act = wezterm.action

local tabrename
tabrename.key = {
	key = "e",
	mods = "LEADER",
	action = act.PromptInputLine({
		description = "Enter new name for tab",
		-- initial_value = "TabName",
		action = wezterm.action_callback(function(window, pane, line)
			-- line will be `nil` if they hit escape without entering anything
			-- An empty string if they just hit enter
			-- Or the actual line of text they wrote
			if line then
				window:active_tab():set_title(line)
			end
		end),
	}),
}

return tabrename
