local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Orchard Breeze with text colors adjusted for a translucent light background.
local paper = "#f4f9ef"
local ink = "#3a4a35"
local sage = "#d9e5cf"
local highlight = "#d4ecc4"
local idle_tab = { bg_color = sage, fg_color = ink }
local hovered_tab = { bg_color = highlight, fg_color = ink }
config.colors = {
	background = paper,
	foreground = ink,
	selection_bg = highlight,
	selection_fg = ink,
	cursor_bg = "#477b3c",
	cursor_border = "#477b3c",
	cursor_fg = paper,
	split = sage,
	tab_bar = {
		active_tab = { bg_color = paper, fg_color = ink },
		inactive_tab = idle_tab,
		inactive_tab_hover = hovered_tab,
		inactive_tab_edge = sage,
		new_tab = idle_tab,
		new_tab_hover = hovered_tab,
	},
	ansi = { "#3a4a35", "#763028", "#2a4e22", "#574310", "#294869", "#5d3865", "#1f4d45", "#444741" },
	brights = { "#4b5645", "#863c33", "#325c29", "#655017", "#345578", "#6b4473", "#275b52", "#525351" },
}
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.force_reverse_video_cursor = false

config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.window_frame = {
	active_titlebar_bg = sage,
	inactive_titlebar_bg = sage,
	active_titlebar_fg = ink,
	inactive_titlebar_fg = ink,
	active_titlebar_border_bottom = sage,
	inactive_titlebar_border_bottom = sage,
	border_left_width = "1px",
	border_right_width = "1px",
	border_top_height = "1px",
	border_bottom_height = "1px",
	border_left_color = sage,
	border_right_color = sage,
	border_top_color = sage,
	border_bottom_color = sage,
}
config.enable_scroll_bar = true

-- Mirror Ghostty's multiplexing keys so switching terminals costs no retraining.
-- WezTerm's own defaults stay live; only CMD+w is genuinely displaced (it closed
-- the whole tab, where Ghostty closes just the pane).
config.keys = {
	{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Next") },
	{ key = "Enter", mods = "SUPER|SHIFT", action = act.TogglePaneZoomState },
	{ key = "w", mods = "SUPER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "w", mods = "SUPER|ALT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "LeftArrow", mods = "OPT", action = act.SendKey({ key = "b", mods = "ALT" }) },
	{ key = "RightArrow", mods = "OPT", action = act.SendKey({ key = "f", mods = "ALT" }) },
}

for _, direction in ipairs({ "Left", "Right", "Up", "Down" }) do
	table.insert(config.keys, {
		key = direction .. "Arrow",
		mods = "SUPER|ALT",
		action = act.ActivatePaneDirection(direction),
	})
	table.insert(config.keys, {
		key = direction .. "Arrow",
		mods = "SUPER|CTRL",
		action = act.AdjustPaneSize({ direction, 10 }),
	})
end

-- Dim unfocused windows so the focused one is obvious at a glance.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

-- get_config_overrides() hands back a copy, so the current value is never the
-- same table we last stored; compare the fields instead of the identity.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Only write when one of the two values we own actually changes; a redundant
	-- set_config_overrides() call would trigger another config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

return config
