#!/usr/bin/env bash

set -euo pipefail

TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export TEST_ROOT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack=$1
  local needle=$2
  [[ $haystack == *"$needle"* ]] || fail "Expected output to contain: $needle"
}

make_temp_dir() {
  mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX"
}

remove_temp_dir() {
  local directory=$1
  [[ $directory == "${TMPDIR:-/tmp}"/dotfiles-test.* ]] || fail "Refusing to remove unexpected test directory: $directory"
  /bin/rm -rf "$directory"
}
