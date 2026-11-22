-- Migrated from tmux, Herdr, Ghostty, WezTerm and iTerm2.

-- Prefix passthrough: ctrl+b starts sequences, so send it on a double press.
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

-- tmux (~/.config/tmux/tmux.conf)
rex.bind("ctrl+b>shift+r", "client.config.reload")
rex.bind("ctrl+b>ctrl+l", "pane.send_key", { key = "ctrl+l" })

-- Herdr (~/.config/herdr/config.toml)
rex.bind("ctrl+b>left", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>down", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>up", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>right", "pane.focus", { direction = "right" })
rex.bind("ctrl+b>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+b>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>shift+7", "client.tab.close")
rex.bind("ctrl+b>w", "session.switch")
rex.bind("ctrl+b>g", "session.switch")

-- WezTerm (~/.config/wezterm/wezterm.lua)
rex.bind("alt+left", "pane.send_key", { key = "alt+b" })
rex.bind("alt+right", "pane.send_key", { key = "alt+f" })
rex.bind("ctrl+cmd+left", "pane.resize", { direction = "left", amount = 10 })
rex.bind("ctrl+cmd+right", "pane.resize", { direction = "right", amount = 10 })
rex.bind("ctrl+cmd+up", "pane.resize", { direction = "up", amount = 10 })
rex.bind("ctrl+cmd+down", "pane.resize", { direction = "down", amount = 10 })

-- iTerm2 (com.googlecode.iterm2.plist)
rex.bind("shift+enter", "pane.send_key", { key = "ctrl+j" })
rex.bind("cmd+left", "pane.send_key", { key = "ctrl+a" })
rex.bind("cmd+right", "pane.send_key", { key = "ctrl+e" })
rex.bind("delete", "pane.send_key", { key = "ctrl+d" })
rex.bind("alt+backspace", "pane.send_key", { key = "alt+backspace" })
rex.bind("cmd+backspace", "pane.send_key", { key = "ctrl+u" })
