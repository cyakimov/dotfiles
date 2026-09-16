{ config, self, ... }:
{
  home.file = {
    ".pi/agent/AGENTS.md".source = "${self}/AGENTS.md";
    ".pi/agent/keybindings.json".source = "${self}/config/pi/keybindings.json";
    ".pi/agent/extensions".source = "${self}/config/pi/extensions";

    # Pi rewrites settings.json at runtime, so it points at the checkout rather
    # than the store. See docs/operations.md.
    ".pi/agent/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/pi/settings.json";
  };
}
