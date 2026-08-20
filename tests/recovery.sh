#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=tests/testlib.sh
. "$SCRIPT_DIR/testlib.sh"

temp_dir=$(make_temp_dir)
trap 'remove_temp_dir "$temp_dir"' EXIT
test_home=$temp_dir/home
legacy_repo=$temp_dir/legacy
test_repo=$temp_dir/repository
mock_bin=$temp_dir/bin
mkdir -p "$test_home" "$legacy_repo" "$test_repo" "$mock_bin"

cp -R "$TEST_ROOT/." "$test_repo"
/bin/rm -rf "$test_repo/.git"
printf '{"nodes":{},"root":"root","version":7}\n' > "$test_repo/flake.lock"
git -C "$test_repo" init -q
git -C "$test_repo" add -A
git -C "$test_repo" \
  -c user.name=Test \
  -c user.email=test@example.invalid \
  -c commit.gpgsign=false \
  commit -qm "test fixture"

while IFS=$'\t' read -r mode relative source; do
  [[ -n ${mode:-} && $mode != \#* ]] || continue
  mkdir -p "$legacy_repo/$(dirname "$source")" "$test_home/$(dirname "$relative")"
  printf 'legacy content for %s\n' "$relative" > "$legacy_repo/$source"
  ln -s "$legacy_repo/$source" "$test_home/$relative"
done < "$test_repo/migration/legacy-links.tsv"

unlink "$test_home/.config/wezterm/wezterm.lua"
rmdir "$test_home/.config/wezterm"
ln -s "$legacy_repo/wezterm/.config/wezterm" "$test_home/.config/wezterm"

unlink "$test_home/.config/mise/config.toml"
rmdir "$test_home/.config/mise"
ln -s "$legacy_repo/mise/.config/mise" "$test_home/.config/mise"
touch "$test_home/.zshenv"

for command_name in darwin-rebuild nix tmutil; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$mock_bin/$command_name"
done
printf "#!/usr/bin/env bash\nif [[ \"\$*\" == \"trust --json=v1\" ]]; then\n  printf '{\"taps\":[],\"formulae\":[\"gromgit/brewtils/taproom\"],\"casks\":[],\"commands\":[]}\\n'\nfi\n" > "$mock_bin/brew"
printf '#!/usr/bin/env bash\nexit 42\n' > "$mock_bin/sudo"
chmod +x "$mock_bin"/*

fixture_status=$(git -C "$test_repo" status --porcelain --untracked-files=normal)
[[ -z $fixture_status ]] || fail "The recovery test fixture is unexpectedly dirty: $fixture_status"

if HOME="$test_home" GIT_CONFIG_GLOBAL=/dev/null PATH="$mock_bin:$PATH" \
  "$test_repo/bin/switch" --apply --legacy-repo "$legacy_repo" > "$temp_dir/switch.out" 2>&1; then
  fail "Switch unexpectedly succeeded with a failing activation command."
fi

while IFS=$'\t' read -r mode relative source; do
  [[ -n ${mode:-} && $mode != \#* ]] || continue
  target=$test_home/$relative
  if [[ ! -f $target || -L $target ]]; then
    sed -n '1,320p' "$temp_dir/switch.out" >&2
    fail "Recovery did not restore a regular file: $target"
  fi
  assert_contains "$(sed -n '1p' "$target")" "legacy content for $relative"
done < "$test_repo/migration/legacy-links.tsv"

[[ -f $test_home/.zshenv && ! -L $test_home/.zshenv && ! -s $test_home/.zshenv ]] || \
  fail "Recovery did not restore the adopted empty .zshenv file."
[[ ! -f $test_home/.local/state/dotfiles-migration/current/activated-at ]] || fail "Failed activation was recorded as successful."
assert_contains "$(sed -n '1,320p' "$temp_dir/switch.out")" "Activation failed"

rollback_log=$temp_dir/rollback.log
printf "#!/usr/bin/env bash\nprintf \"%%s\\\\n\" \"\$*\" > \"\$ROLLBACK_LOG\"\n" > "$mock_bin/sudo"
chmod +x "$mock_bin/sudo"
HOME="$test_home" GIT_CONFIG_GLOBAL=/dev/null PATH="$mock_bin:$PATH" ROLLBACK_LOG="$rollback_log" \
  "$test_repo/bin/rollback" --system --apply >/dev/null
assert_contains "$(sed -n '1p' "$rollback_log")" "switch --rollback"

printf 'PASS: failed activation restores files and rollback targets the previous generation\n'
