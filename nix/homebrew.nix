_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };

    taps = [ "gromgit/brewtils" ];

    brews = [
      "mactop"
      "mole"
      {
        name = "gromgit/brewtils/taproom";
        trusted = true;
      }
    ];

    casks = [
      "bruno"
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "openlogi"
      "unnaturalscrollwheels"
      "wezterm"
    ];
  };
}
