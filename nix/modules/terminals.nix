{ self, ... }:
{
  xdg.configFile = {
    "ghostty/config".source = "${self}/config/terminals/ghostty.conf";
    "herdr/config.toml".source = "${self}/config/herdr/config.toml";
    "wezterm/wezterm.lua".source = "${self}/config/terminals/wezterm.lua";
  };
}
