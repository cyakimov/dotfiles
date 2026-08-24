_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };

    brews = [
      "mactop"
      "mole"
    ];

    casks = [
      "bruno"
      "codex"
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "openlogi"
      "unnaturalscrollwheels"
      "visual-studio-code"
      "wezterm"
    ];
  };
}
