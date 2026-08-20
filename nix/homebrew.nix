_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };

    taps = [ "gromgit/brewtils" ];

    brews = [
      "herdr"
      "mactop"
      "mole"
      "gromgit/brewtils/taproom"
    ];

    casks = [
      "1password-cli"
      "codex"
      "copilot-cli"
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "jetbrains-toolbox"
      "spotify"
      "unnaturalscrollwheels"
      "visual-studio-code"
    ];
  };
}
