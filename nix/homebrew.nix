_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
      extraEnv.XDG_CONFIG_HOME = "/Users/cyakimov/.config";
    };

    brews = [
      "mactop"
      "mole"
      "rbenv"
    ];

    casks = [
      "bruno"
      "claude-code"
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
