{ self, ... }:
{
  xdg.configFile = {
    "ghostty/config".source = "${self}/config/terminals/ghostty.conf";
    "wezterm/wezterm.lua".source = "${self}/config/terminals/wezterm.lua";
    "rex/init.lua".source = "${self}/config/terminals/rex.lua";
  };
}
