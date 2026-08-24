{
  inputs,
  pkgs,
  self,
  ...
}:
{
  home-manager.users.cyakimov = {
    home.packages = [
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
    ];

    programs.git.includes = [
      { path = "~/.config/git/personal.inc"; }
    ];

    xdg.configFile = {
      "herdr/config.toml".source = "${self}/config/herdr/config.toml";
      "git/personal.inc".source = "${self}/config/git/personal.inc";
    };
  };

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
