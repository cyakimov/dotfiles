{ config, ... }:
let
  checkout = "${config.home.homeDirectory}/dotfiles/config/herdr-app";
in
{
  xdg.configFile = {
    "herdr-app/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${checkout}/settings.json";
    "herdr-app/keys.json".source = config.lib.file.mkOutOfStoreSymlink "${checkout}/keys.json";
    "herdr-app/themes/rose-pine-moon.json".source =
      config.lib.file.mkOutOfStoreSymlink "${checkout}/themes/rose-pine-moon.json";
  };
}
