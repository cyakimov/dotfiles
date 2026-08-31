{ config, lib, ... }:
let
  workHome = config.home-manager.users.cyakimov;
in
{
  homebrew.onActivation.cleanup = lib.mkForce "none";

  assertions = [
    {
      assertion = !(lib.any (package: lib.getName package == "herdr") workHome.home.packages);
      message = "Herdr is not permitted in the work profile.";
    }
    {
      assertion = !(workHome.xdg.configFile ? "herdr/config.toml");
      message = "Herdr configuration is not permitted in the work profile.";
    }
    {
      assertion = !(lib.elem "pi-coding-agent" config.homebrew.brews);
      message = "The Pi coding agent is not permitted in the work profile.";
    }
    {
      assertion = !(lib.any (package: lib.getName package == "openspec") workHome.home.packages);
      message = "OpenSpec is not permitted in the work profile.";
    }
    {
      assertion = !(workHome.home.file ? ".pi/agent/keybindings.json");
      message = "Pi configuration is not permitted in the work profile.";
    }
    {
      assertion = !workHome.programs.git.enable;
      message = "The work profile must not manage Git configuration.";
    }
    {
      assertion = !(workHome.xdg.configFile ? "git/config");
      message = "Nix must not write the work Git configuration.";
    }
    {
      assertion = !(workHome.xdg.configFile ? "git/personal.inc");
      message = "Personal Git identity is not permitted in the work profile.";
    }
  ];
}
