{ self, ... }:
{
  xdg.configFile = {
    "ghostty/config".source = "${self}/config/terminals/ghostty.conf";
    "wezterm/wezterm.lua".source = "${self}/config/terminals/wezterm.lua";
  };
}
