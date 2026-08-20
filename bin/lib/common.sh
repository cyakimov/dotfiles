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

nix_flakes() {
  nix --extra-experimental-features "nix-command flakes" "$@"
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

first_activation_etc_conflicts() {
  local etc_root=$1
  local name
  local path

  for name in bashrc zshrc; do
    path=$etc_root/$name
    if [[ -e $path || -L $path ]] && ! is_nix_owned_path "$path"; then
      printf '%s\n' "$path"
    fi
  done
}

restore_legacy_topology() {
  local backup_dir=$1
  local ancestor
  local ancestor_relative
  local backup_file
  local errors=0
  local link_source
  local mode
  local original
  local recovered
  local relative
  local resolved
  local target
  local temporary

  [[ -f $backup_dir/links.tsv && -f $backup_dir/folded.tsv ]] || {
    warn "Invalid migration backup: $backup_dir"
    return 1
  }

  while IFS=$'\t' read -r ancestor_relative _ temporary; do
    [[ -n ${ancestor_relative:-} ]] || continue
    ancestor=$HOME/$ancestor_relative
    if [[ ! -e $ancestor && ! -L $ancestor && -d $temporary ]]; then
      if ! mv "$temporary" "$ancestor"; then
        warn "Could not recover the unfolded directory: $ancestor"
        errors=$((errors + 1))
      fi
    fi
  done < "$backup_dir/folded.tsv"

  while IFS=$'\t' read -r mode relative original; do
    [[ -n ${mode:-} ]] || continue
    target=$HOME/$relative
    backup_file=$backup_dir/files/$relative

    if [[ ! -f $backup_file ]]; then
      warn "Recovery backup is missing: $backup_file"
      errors=$((errors + 1))
      continue
    fi

    case $original in
      adopted:empty)
        if [[ -L $target ]] && is_nix_owned_path "$target"; then
          unlink "$target"
        fi
        if [[ ! -e $target && ! -L $target ]]; then
          mkdir -p "$(dirname "$target")"
          cp -p "$backup_file" "$target"
        elif [[ ! -f $target || -L $target ]] || ! cmp -s "$target" "$backup_file"; then
          warn "Left unexpected adopted path untouched during recovery: $target"
          errors=$((errors + 1))
        fi
        ;;
      folded:*)
        if [[ -L $target ]] && is_nix_owned_path "$target"; then
          unlink "$target"
        fi
        if [[ ! -e $target && ! -L $target ]]; then
          mkdir -p "$(dirname "$target")"
          cp -p "$backup_file" "$target"
        elif [[ ! -f $target || -L $target ]] || ! cmp -s "$target" "$backup_file"; then
          warn "Left unexpected folded path untouched during recovery: $target"
          errors=$((errors + 1))
        fi
        ;;
      *)
        if [[ -L $target ]] && [[ $(readlink "$target") == "$original" ]]; then
          continue
        fi

        if [[ $original == /* ]]; then
          link_source=$original
        else
          link_source=$(dirname "$target")/$original
        fi
        if ! canonical_existing_path "$link_source" >/dev/null 2>&1; then
          warn "Recorded legacy link target is missing: $link_source"
          errors=$((errors + 1))
          continue
        fi

        if [[ -L $target ]] && is_nix_owned_path "$target"; then
          unlink "$target"
        fi

        if [[ ! -e $target && ! -L $target ]]; then
          mkdir -p "$(dirname "$target")"
          if ! ln -s "$original" "$target"; then
            cp -p "$backup_file" "$target"
            warn "Could not restore the recorded legacy link: $target"
            errors=$((errors + 1))
          fi
        elif [[ -f $target && ! -L $target ]] && cmp -s "$target" "$backup_file"; then
          unlink "$target"
          if ! ln -s "$original" "$target"; then
            cp -p "$backup_file" "$target"
            warn "Could not restore the recorded legacy link: $target"
            errors=$((errors + 1))
          fi
        else
          warn "Left unexpected path untouched during topology recovery: $target"
          errors=$((errors + 1))
        fi
        ;;
    esac
  done < "$backup_dir/links.tsv"

  while IFS=$'\t' read -r ancestor_relative original temporary; do
    [[ -n ${ancestor_relative:-} ]] || continue
    ancestor=$HOME/$ancestor_relative

    if [[ -L $ancestor ]] && [[ $(readlink "$ancestor") == "$original" ]]; then
      continue
    fi
    if [[ -L $ancestor ]]; then
      warn "Left foreign directory link untouched during recovery: $ancestor"
      errors=$((errors + 1))
      continue
    fi

    if [[ $original == /* ]]; then
      link_source=$original
    else
      link_source=$(dirname "$ancestor")/$original
    fi
    resolved=$(canonical_existing_path "$link_source" 2>/dev/null || true)
    if [[ -z $resolved || ! -d $resolved ]]; then
      warn "Recorded folded directory target is missing: $link_source"
      errors=$((errors + 1))
      continue
    fi

    if [[ -d $ancestor ]]; then
      if ! diff -qr "$ancestor" "$resolved" >/dev/null 2>&1; then
        warn "Unfolded directory changed during activation and was left untouched: $ancestor"
        errors=$((errors + 1))
        continue
      fi

      recovered=$backup_dir/recovered-folded/$ancestor_relative
      if [[ -e $recovered || -L $recovered ]]; then
        warn "Recovered directory destination already exists: $recovered"
        errors=$((errors + 1))
        continue
      fi
      mkdir -p "$(dirname "$recovered")"
      if mv "$ancestor" "$recovered"; then
        if ! ln -s "$original" "$ancestor"; then
          mv "$recovered" "$ancestor"
          warn "Could not restore the folded directory link: $ancestor"
          errors=$((errors + 1))
        fi
      else
        warn "Could not preserve the unfolded directory: $ancestor"
        errors=$((errors + 1))
      fi
    elif [[ ! -e $ancestor && ! -L $ancestor ]]; then
      mkdir -p "$(dirname "$ancestor")"
      if ! ln -s "$original" "$ancestor"; then
        warn "Could not restore the folded directory link: $ancestor"
        errors=$((errors + 1))
      fi
    else
      warn "Left unexpected folded directory path untouched during recovery: $ancestor"
      errors=$((errors + 1))
    fi
  done < "$backup_dir/folded.tsv"

  (( errors == 0 ))
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
