#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=tests/testlib.sh
. "$SCRIPT_DIR/testlib.sh"

assert_unique_lines() {
  local file=$1
  local duplicates

  duplicates=$(sed '/^#/d;/^$/d' "$file" | LC_ALL=C sort | uniq -d)
  [[ -z $duplicates ]] || fail "Duplicate entries in $file: $duplicates"
}

assert_unique_column() {
  local file=$1
  local column=$2
  local duplicates

  duplicates=$(sed '/^#/d;/^$/d' "$file" | cut -f"$column" | LC_ALL=C sort | uniq -d)
  [[ -z $duplicates ]] || fail "Duplicate column $column entries in $file: $duplicates"
}

legacy_manifest=$TEST_ROOT/migration/legacy-links.tsv
adoptable_manifest=$TEST_ROOT/migration/adoptable-targets.tsv
provider_manifest=$TEST_ROOT/migration/replacement-commands.tsv
home_targets=$TEST_ROOT/migration/home-manager-targets.txt

awk -F '\t' '
  $0 !~ /^#/ && $0 != "" {
    if (NF != 3 || ($1 != "managed" && $1 != "mutable" && $1 != "legacy")) exit 1
  }
' "$legacy_manifest" || fail "Invalid legacy migration manifest."

awk -F '\t' '
  $0 !~ /^#/ && $0 != "" {
    if (NF != 2 || $1 != "empty") exit 1
  }
' "$adoptable_manifest" || fail "Invalid adoptable-target manifest."

awk -F '\t' '
  $0 !~ /^#/ && $0 != "" {
    if (NF != 2 || ($1 != "nix" && $1 != "brew")) exit 1
  }
' "$provider_manifest" || fail "Invalid replacement-provider manifest."

assert_unique_column "$legacy_manifest" 2
assert_unique_column "$adoptable_manifest" 2
assert_unique_column "$provider_manifest" 2
assert_unique_lines "$home_targets"
assert_unique_lines "$TEST_ROOT/migration/homebrew-formulae.txt"
assert_unique_lines "$TEST_ROOT/migration/mise-tools.txt"

while IFS=$'\t' read -r strategy relative; do
  [[ -n ${strategy:-} && $strategy != \#* ]] || continue
  grep -Fxq "$relative" "$home_targets" || fail "Adopted target is not declared as Home Manager-owned: $relative"
done < "$adoptable_manifest"

for retained_formula in herdr mactop mole taproom; do
  if grep -Fxq "$retained_formula" "$TEST_ROOT/migration/homebrew-formulae.txt"; then
    fail "Homebrew exception is incorrectly scheduled for cleanup: $retained_formula"
  fi
done

printf 'PASS: migration manifests are valid and internally consistent\n'
