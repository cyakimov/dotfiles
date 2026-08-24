{
  inputs,
  pkgs,
  self,
  ...
}:
{
  home-manager.users.cyakimov = {
    home = {
      packages = [
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
        inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent
        (pkgs.callPackage ../nix/packages/openspec.nix { src = inputs.openspec; })
      ];

      file = {
        ".pi/agent/AGENTS.md".source = "${self}/AGENTS.md";
        ".pi/agent/keybindings.json".source = "${self}/config/pi/keybindings.json";
      };
    };

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
