{
  config,
  lib,
  pkgs,
  self,
  inputs,
  ...
}:
let
  nvmInit = ''
    export NVM_DIR="$HOME/.nvm"
    [ -s "${inputs.nvm}/nvm.sh" ] && . "${inputs.nvm}/nvm.sh"

    _nvm_auto_use() {
      local nvmrc_dir nvmrc_version missing_key default_version current_version
      if [[ "''${_NVM_AUTO_LAST_PWD:-}" == "$PWD" ]]; then
        return
      fi
      _NVM_AUTO_LAST_PWD="$PWD"
      nvmrc_dir="$(nvm_find_up .nvmrc)"

      if [[ -n "$nvmrc_dir" ]]; then
        nvmrc_version="$(<"$nvmrc_dir/.nvmrc")"
        if [[ "$(nvm version "$nvmrc_version")" == "N/A" ]]; then
          missing_key="$nvmrc_dir:$nvmrc_version"
          if [[ "''${_NVM_AUTO_MISSING:-}" != "$missing_key" ]]; then
            printf 'nvm: Node %s is not installed; run `nvm install` in this project.\n' "$nvmrc_version" >&2
            _NVM_AUTO_MISSING="$missing_key"
          fi
          return
        fi

        unset _NVM_AUTO_MISSING
        current_version="$(nvm current)"
        if [[ "$current_version" != "$(nvm version "$nvmrc_version")" ]]; then
          nvm use --silent "$nvmrc_version" >/dev/null
        fi
        return
      fi

      unset _NVM_AUTO_MISSING
      default_version="$(nvm version default)"
      if [[ "$default_version" != "N/A" && "$(nvm current)" != "$default_version" ]]; then
        nvm use --silent default >/dev/null
      fi
    }
  '';
in
{
  home.file = {
    ".p10k.zsh".source = "${self}/config/shell/p10k.zsh";
    ".zsh_aliases".source = "${self}/config/shell/aliases.zsh";
  };

  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      initExtra = ''
        ${nvmInit}
        _nvm_auto_use
        case ";''${PROMPT_COMMAND:-};" in
          *";_nvm_auto_use;"*) ;;
          *) PROMPT_COMMAND="_nvm_auto_use''${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
        esac
      '';
      historyControl = [
        "erasedups"
        "ignorespace"
      ];
      historyFileSize = 50000;
      historySize = 50000;
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    zsh = {
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

          bindkey $'\e[1;3D' backward-word
          bindkey $'\e[1;3C' forward-word
          bindkey $'\e\e[D' backward-word
          bindkey $'\e\e[C' forward-word
        '')
        (lib.mkOrder 1300 ''
          ${nvmInit}
          autoload -U add-zsh-hook
          add-zsh-hook chpwd _nvm_auto_use
          _nvm_auto_use
        '')
      ];
    };
  };
}
