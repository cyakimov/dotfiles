#!/usr/bin/env bash

set -euo pipefail

DOTFILES_ROOT=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
DOTFILES_STATE_ROOT=${XDG_STATE_HOME:-"$HOME/.local/state"}/dotfiles-migration

say() {
  printf '%s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_apple_silicon_macos() {
  [[ $(uname -s) == "Darwin" ]] || die "This configuration currently supports macOS only."
  [[ $(uname -m) == "arm64" ]] || die "This configuration currently supports Apple Silicon only."
}

homebrew_taproom_is_trusted() {
  local trust_json

  command -v brew >/dev/null 2>&1 || return 1
  trust_json=$(brew trust --json=v1 2>/dev/null) || return 1
  [[ $trust_json == *'"gromgit/brewtils"'* || $trust_json == *'"gromgit/brewtils/taproom"'* ]]
}

load_nix_environment() {
  if command -v nix >/dev/null 2>&1; then
    return
  fi

  local daemon_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  if [[ -r $daemon_profile ]]; then
    set +u
    # shellcheck disable=SC1090
    . "$daemon_profile"
    set -u
  fi
}

canonical_existing_path() {
  local path=$1
  local link

  while [[ -L $path ]]; do
    link=$(readlink "$path")
    if [[ $link == /* ]]; then
      path=$link
    else
      path=$(dirname "$path")/$link
    fi
  done

  [[ -e $path ]] || return 1
  printf '%s/%s\n' "$(CDPATH='' cd -- "$(dirname -- "$path")" && pwd -P)" "$(basename -- "$path")"
}

is_nix_owned_path() {
  local resolved
  resolved=$(canonical_existing_path "$1" 2>/dev/null) || return 1
  [[ $resolved == /nix/store/* ]]
}

nearest_symlink_ancestor() {
  local path=$1

  while [[ $path != "$HOME" && $path != "/" ]]; do
    if [[ -L $path ]]; then
      printf '%s\n' "$path"
      return
    fi
    path=$(dirname "$path")
  done

  return 1
}

timestamp_utc() {
  date -u '+%Y%m%dT%H%M%SZ'
}

epoch_now() {
  date '+%s'
}

age_in_days() {
  local then_epoch=$1
  printf '%s\n' $(( ($(epoch_now) - then_epoch) / 86400 ))
}

latest_backup_dir() {
  [[ -d $DOTFILES_STATE_ROOT/backups ]] || return 1
  find "$DOTFILES_STATE_ROOT/backups" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort | tail -n 1
}

managed_branch_is_clean() {
  git -C "$DOTFILES_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  [[ -z $(git -C "$DOTFILES_ROOT" status --porcelain --untracked-files=normal 2>/dev/null) ]]
}

find_project_mise_config() {
  find "$HOME" \
    \( \
      -path "$HOME/.cache" -o \
      -path "$HOME/.git" -o \
      -path "$HOME/.local" -o \
      -path "$HOME/.Trash" -o \
      -path "$HOME/Library" \
    \) -prune -o \
    \( -type f -o -type l \) \
    \( -name mise.toml -o -name .mise.toml -o -name .tool-versions \) \
    -print -quit 2>/dev/null
}
