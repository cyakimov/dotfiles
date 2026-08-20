{
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [ ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfreePredicate =
    package:
    builtins.elem (lib.getName package) [
      "claude-code"
    ];

  nix = {
    enable = true;
    channel.enable = false;
    gc.automatic = false;
    optimise.automatic = false;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system = {
    configurationRevision = self.rev or self.dirtyRev or null;
    primaryUser = "cyakimov";
    stateVersion = 6;

    defaults.NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 12;
      KeyRepeat = 2;
    };
  };

  users.users.cyakimov = {
    home = "/Users/cyakimov";
  };

  environment.systemPackages = [ pkgs.git ];
  environment.pathsToLink = [
    "/share/bash-completion"
    "/share/zsh"
  ];
}
