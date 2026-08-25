{
  inputs,
  pkgs,
  self,
  ...
}:
{
  # nixpkgs lags upstream claude-code releases; track the latest release
  # ourselves on the personal profile until nixpkgs catches up.
  nixpkgs.overlays = [
    (final: prev: {
      claude-code = prev.claude-code.override {
        manifest = final.lib.importJSON ../nix/packages/claude-code-manifest.json;
      };
    })
  ];

  home-manager.users.cyakimov = {
    imports = [ ../nix/modules/git.nix ];

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
