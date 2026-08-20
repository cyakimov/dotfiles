{
  inputs,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./modules/agents.nix
    ./modules/git.nix
    ./modules/shell.nix
    ./modules/terminals.nix
    ./modules/tmux.nix
  ];

  home = {
    username = "cyakimov";
    homeDirectory = "/Users/cyakimov";
    stateVersion = "26.05";
    packages = import ./packages.nix { inherit inputs pkgs; };

    sessionPath = [
      "/etc/profiles/per-user/cyakimov/bin"
      "/run/current-system/sw/bin"
      "$HOME/.local/bin"
      "$HOME/bin"
      "$HOME/go/bin"
      "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/usr/local/sbin"
    ];

    sessionVariables = {
      EDITOR = "nano";
      GOPATH = "/Users/cyakimov/go";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      MISE_GLOBAL_CONFIG_FILE = "/Users/cyakimov/.config/mise/nix-global.toml";
      VISUAL = "nano";
    };
  };

  home.file.".docker/cli-plugins/docker-compose".source = "${pkgs.docker-compose}/bin/docker-compose";

  programs.home-manager.enable = true;

  xdg.enable = true;

  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
      message = "This configuration currently supports Apple Silicon macOS only.";
    }
    {
      assertion = (self ? rev) || (self ? dirtyRev);
      message = "Build from a Git checkout so the activated revision remains auditable.";
    }
  ];
}
