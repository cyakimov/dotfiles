# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

BUN_INSTALL="$HOME/.bun"

# PATH Configuration
# Consolidate all PATH modifications for better performance
path_dirs=(
    "$HOME/go/bin"
    "$HOME/.krew/bin"
    "/usr/local/sbin"
    "$HOME/n/bin"
    "$HOME/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    "$HOME/.local/bin"
    "$PYENV_ROOT/bin"
    "$BUN_INSTALL/bin"
)

# Add existing PATH directories to our array
for dir in "${path_dirs[@]}"; do
    [[ -d "$dir" ]] && PATH="$dir:$PATH"
done
export PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# ===============================================
# OH-MY-ZSH CONFIGURATION
# ===============================================
# Disable magic functions that can interfere with pasting
DISABLE_MAGIC_FUNCTIONS="true"

# Performance: disable marking untracked files as dirty for large repos
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Auto-update settings
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' frequency 13   # update every 13 days

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    history-substring-search
    colored-man-pages
    zsh-autosuggestions
    kubectl
)

source $ZSH/oh-my-zsh.sh

# ===============================================
# HISTORY CONFIGURATION
# ===============================================
HISTSIZE=50000                   # How many lines of history to keep in memory
HISTFILESIZE=50000               # How many lines to keep in the history file
SAVEHIST=50000                   # Number of history entries to save to disk
HISTFILE=~/.zsh_history         # Where to save history to disk
HISTDUP=erase                    # Erase duplicates in the history file
setopt appendhistory             # Append history to the history file (no overwriting)
setopt sharehistory              # Share history across terminals
setopt incappendhistory          # Immediately append to the history file, not just when a term is killed
setopt hist_ignore_all_dups      # Remove older duplicate entries from history
setopt hist_save_no_dups         # Do not save duplicated entries to history file
setopt hist_ignore_dups          # Do not record an entry that was just recorded again
setopt hist_ignore_space         # Do not record an entry starting with a space
setopt hist_verify               # Show command with history expansion to user before running it
setopt hist_reduce_blanks        # Remove superfluous blanks before recording entry

# ===============================================
# COMPLETION CONFIGURATION
# ===============================================
# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Better completion menu
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# User configuration
export GOPATH=$HOME/go

# ===============================================
# USER CONFIGURATION
# ===============================================
# Set preferred editor
export EDITOR=nano

# Language environment
# export LANG=en_US.UTF-8

# ===============================================
# EXTERNAL TOOLS & INTEGRATIONS
# ===============================================
# Powerlevel10k prompt configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# FZF fuzzy finder integration
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Lazy load heavy tools for better performance
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Development tools initialization
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# Tools
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Load aliases
[[ -f "$HOME/.zsh_aliases" ]] && source "$HOME/.zsh_aliases"
[[ -f "$ZSH_CUSTOM/aliases.zsh" ]] && source "$ZSH_CUSTOM/aliases.zsh"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
