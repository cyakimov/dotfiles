{
  inputs,
  pkgs,
  self,
  ...
}:
{
  home-manager.users.cyakimov.home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
  ];
  home-manager.users.cyakimov.xdg.configFile."herdr/config.toml".source =
    "${self}/config/herdr/config.toml";

  homebrew.casks = [
    "1password-cli"
    "appcleaner"
    "balenaetcher"
    "chatgpt"
    "codex"
    "copilot-cli"
    "discord"
    "google-chrome"
    "jetbrains-toolbox"
    "ollamac"
    "opensuperwhisper"
    "spotify"
    "transmission"
    "visual-studio-code"
    "vlc"
    "zoom"
  ];
}
