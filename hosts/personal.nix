{
  inputs,
  pkgs,
  self,
  ...
}:
{
  home-manager.users.cyakimov = {
    imports = [ ../nix/modules/git.nix ];

    home = {
      packages = [
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
        inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk
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

  homebrew.brews = [
    "pi-coding-agent"
    "raine/workmux/workmux"
    "tuicr"
  ];

  homebrew.casks = [
    "1password-cli"
    "appcleaner"
    "balenaetcher"
    "chatgpt"
    "copilot-cli"
    "discord"
    "google-chrome"
    "jetbrains-toolbox"
    "ollamac"
    "opensuperwhisper"
    "spotify"
    "transmission"
    "vlc"
    "zoom"
  ];
}
