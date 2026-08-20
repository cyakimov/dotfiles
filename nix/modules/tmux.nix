{ self, ... }:
{
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile "${self}/config/tmux/tmux.conf";
  };
}
