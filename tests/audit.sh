#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=tests/testlib.sh
. "$SCRIPT_DIR/testlib.sh"

temp_dir=$(make_temp_dir)
trap 'remove_temp_dir "$temp_dir"' EXIT
mkdir -p "$temp_dir/home"

output=$(HOME="$temp_dir/home" "$TEST_ROOT/bin/audit")
assert_contains "$output" "Legacy and managed home paths"
assert_contains "$output" "Replacement command providers"

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  assert_contains "$output" "/nix/var/nix/profiles/default/bin/nix"
fi

printf 'PASS: audit is read-only against an empty home\n'
