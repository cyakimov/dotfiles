{
  inputs,
  pkgs,
  ...
}:
{
  home-manager.users.cyakimov.home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
  ];

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
