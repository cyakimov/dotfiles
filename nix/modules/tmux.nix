{ pkgs, self, ... }:
let
  tmuxVersion = "3.7c";
in
{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux.overrideAttrs (oldAttrs: {
      version = tmuxVersion;
      src = pkgs.fetchurl {
        url = "https://github.com/tmux/tmux/archive/refs/tags/${tmuxVersion}.tar.gz";
        hash = "sha256-XnsPUztm5WM+K3Kp1IP5U0o0OrcBHrJiG2MJ37pVPao=";
      };
      patches = [ ];
      configureFlags = oldAttrs.configureFlags ++ [ "--disable-jemalloc" ];
    });
    extraConfig = builtins.readFile "${self}/config/tmux/tmux.conf";
  };
}
