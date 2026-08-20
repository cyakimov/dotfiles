{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  home.file = {
    ".p10k.zsh".source = "${self}/config/shell/p10k.zsh";
    ".zsh_aliases".source = "${self}/config/shell/aliases.zsh";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [
      "erasedups"
      "ignorespace"
    ];
    historyFileSize = 50000;
    historySize = 50000;
    initExtra = ''
      command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"
    '';
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    historySubstringSearch.enable = true;

    history = {
      append = true;
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      path = "${config.home.homeDirectory}/.zsh_history";
      save = 50000;
      saveNoDups = true;
      share = true;
      size = 50000;
    };

    localVariables.DISABLE_MAGIC_FUNCTIONS = "true";

    oh-my-zsh = {
      enable = true;
      plugins = [
        "colored-man-pages"
        "git"
      ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      (lib.mkOrder 1200 ''
        typeset -U path PATH

        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh"
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' menu select

        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
        [[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

        command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
        command -v treepi >/dev/null 2>&1 && eval "$(treepi shell-init zsh)"

        bindkey $'\e[1;3D' backward-word
        bindkey $'\e[1;3C' forward-word
        bindkey $'\e\e[D' backward-word
        bindkey $'\e\e[C' forward-word
      '')
    ];
  };
}
