{ config, lib, ... }:
let
  workHome = config.home-manager.users.cyakimov;
in
{
  assertions = [
    {
      assertion = !(lib.any (package: lib.getName package == "herdr") workHome.home.packages);
      message = "Herdr is not permitted in the work profile.";
    }
    {
      assertion = !(workHome.xdg.configFile ? "herdr/config.toml");
      message = "Herdr configuration is not permitted in the work profile.";
    }
  ];

  homebrew.casks = [
    "gcloud-cli"
  ];
}
