#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=tests/testlib.sh
. "$SCRIPT_DIR/testlib.sh"

temp_dir=$(make_temp_dir)
trap 'remove_temp_dir "$temp_dir"' EXIT
mkdir -p "$temp_dir/home"

if HOME="$temp_dir/home" "$TEST_ROOT/bin/cleanup-legacy" > "$temp_dir/cleanup.out" 2>&1; then
  fail "Cleanup ran without a successful activation record."
fi
assert_contains "$(sed -n '1,120p' "$temp_dir/cleanup.out")" "No successful migration activation is recorded"

if HOME="$temp_dir/home" "$TEST_ROOT/bin/purge-legacy" > "$temp_dir/purge.out" 2>&1; then
  fail "Purge ran without a cleanup record."
fi
assert_contains "$(sed -n '1,120p' "$temp_dir/purge.out")" "Legacy cleanup has not completed"

state_dir=$temp_dir/home/.local/state/dotfiles-migration/current
mkdir -p "$state_dir" "$temp_dir/home/Development/project"
date '+%s' > "$state_dir/activated-at"

if HOME="$temp_dir/home" "$TEST_ROOT/bin/cleanup-legacy" > "$temp_dir/cleanup-age.out" 2>&1; then
  fail "Cleanup ran before the 30-day proving period ended."
fi
assert_contains "$(sed -n '1,120p' "$temp_dir/cleanup-age.out")" "Legacy cleanup is locked for 30 days"

printf 'node 24\n' > "$temp_dir/project-tool-versions"
ln -s "$temp_dir/project-tool-versions" "$temp_dir/home/Development/project/.tool-versions"
printf '0\n' > "$state_dir/cleaned-at"

if HOME="$temp_dir/home" "$TEST_ROOT/bin/purge-legacy" > "$temp_dir/purge-project.out" 2>&1; then
  fail "Purge accepted a project-local Mise configuration symlink."
fi
assert_contains "$(sed -n '1,120p' "$temp_dir/purge-project.out")" "Mise-compatible project configuration still exists"

printf 'PASS: cleanup and purge require their safety gates\n'
