#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=tests/testlib.sh
. "$SCRIPT_DIR/testlib.sh"

temp_dir=$(make_temp_dir)
trap 'remove_temp_dir "$temp_dir"' EXIT
test_home=$temp_dir/home
legacy_repo=$temp_dir/legacy
mkdir -p "$test_home" "$legacy_repo"

while IFS=$'\t' read -r mode relative source; do
  [[ -n ${mode:-} && $mode != \#* ]] || continue
  mkdir -p "$legacy_repo/$(dirname "$source")" "$test_home/$(dirname "$relative")"
  printf 'legacy content for %s\n' "$relative" > "$legacy_repo/$source"
  if [[ $relative != ".config/wezterm/wezterm.lua" ]]; then
    ln -s "$legacy_repo/$source" "$test_home/$relative"
  fi
done < "$TEST_ROOT/migration/legacy-links.tsv"

rmdir "$test_home/.config/wezterm"
ln -s "$legacy_repo/wezterm/.config/wezterm" "$test_home/.config/wezterm"

before=$(find "$test_home" -type l -print | LC_ALL=C sort)
output=$(HOME="$test_home" "$TEST_ROOT/bin/switch" --legacy-repo "$legacy_repo")
after=$(find "$test_home" -type l -print | LC_ALL=C sort)

[[ $before == "$after" ]] || fail "Dry-run switch changed the test home."
assert_contains "$output" "Dry run only"
assert_contains "$output" "Homebrew cleanup: disabled"
assert_contains "$output" "unfold managed"

etc_root=$temp_dir/etc
mkdir -p "$etc_root"
printf 'system bash configuration\n' > "$etc_root/bashrc"

if HOME="$test_home" DOTFILES_ETC_ROOT="$etc_root" \
  "$TEST_ROOT/bin/switch" --apply --legacy-repo "$legacy_repo" > "$temp_dir/etc.out" 2>&1; then
  fail "Switch accepted a first-activation /etc conflict."
fi
assert_contains "$(sed -n '1,240p' "$temp_dir/etc.out")" "sudo mv $etc_root/bashrc $etc_root/bashrc.before-nix-darwin"
[[ -L $test_home/.zshrc ]] || fail "System preflight changed the test home."

touch "$etc_root/bashrc.before-nix-darwin"
if HOME="$test_home" DOTFILES_ETC_ROOT="$etc_root" \
  "$TEST_ROOT/bin/switch" --apply --legacy-repo "$legacy_repo" > "$temp_dir/etc-backup.out" 2>&1; then
  fail "Switch accepted simultaneous system shell file and backup paths."
fi
assert_contains "$(sed -n '1,240p' "$temp_dir/etc-backup.out")" "Both $etc_root/bashrc and $etc_root/bashrc.before-nix-darwin exist"

foreign_target=$temp_dir/foreign
printf 'foreign\n' > "$foreign_target"
unlink "$test_home/.zshrc"
ln -s "$foreign_target" "$test_home/.zshrc"

if HOME="$test_home" "$TEST_ROOT/bin/switch" --legacy-repo "$legacy_repo" > "$temp_dir/foreign.out" 2>&1; then
  fail "Switch accepted a foreign symlink."
fi
assert_contains "$(sed -n '1,200p' "$temp_dir/foreign.out")" "does not point into the expected legacy checkout"

unlink "$test_home/.zshrc"
ln -s "$legacy_repo/zsh/.zshrc" "$test_home/.zshrc"
printf 'foreign zsh environment\n' > "$test_home/.zshenv"

if HOME="$test_home" "$TEST_ROOT/bin/switch" --legacy-repo "$legacy_repo" > "$temp_dir/new-target.out" 2>&1; then
  fail "Switch accepted an unmanaged new Home Manager target."
fi
assert_contains "$(sed -n '1,240p' "$temp_dir/new-target.out")" "is not the declared empty regular file"

printf 'PASS: switch dry run preserves links and rejects foreign targets\n'
