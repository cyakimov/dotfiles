#!/usr/bin/env bash
# Static checks for the vendored Pi extensions in config/pi/extensions.
#
# The interactive TUI proofs from the upstream suite are deliberately omitted:
# they need Pi installed and a tmux session, which CI does not have. What
# remains runs anywhere, plus a strict TypeScript typecheck whenever both tsc
# and an installed Pi package are present.
#
# Adapted from https://github.com/kunchenguid/dotfiles (tests/pi-calm.test.sh),
# MIT License, Copyright (c) 2026 Kun Chen - see config/pi/extensions/calm/LICENSE.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

EXT_DIR="$ROOT/config/pi/extensions"
CALM_DIR="$EXT_DIR/calm"
TITLE_EXT="$EXT_DIR/terminal-status-title.js"

# Pi ships as a Homebrew formula here, not a global npm package, so probe both.
pi_package_dir() {
  local candidate
  if [ -n "${PI_TEST_PACKAGE_DIR:-}" ]; then
    printf '%s\n' "$PI_TEST_PACKAGE_DIR"
    return 0
  fi
  for candidate in \
    "$(npm root -g 2>/dev/null)/@earendil-works/pi-coding-agent" \
    "/opt/homebrew/opt/pi-coding-agent/libexec/lib/node_modules/@earendil-works/pi-coding-agent"
  do
    if [ -f "$candidate/package.json" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

test_attribution_preserved() {
  local file
  [ -f "$CALM_DIR/LICENSE" ] || fail "calm LICENSE is missing"
  grep -q "MIT License" "$CALM_DIR/LICENSE" || fail "calm LICENSE lost the MIT permission text"
  grep -q "Copyright (c) 2026 Kun Chen" "$CALM_DIR/LICENSE" \
    || fail "calm LICENSE lost the copyright notice"

  for file in "$CALM_DIR/index.ts" "$CALM_DIR"/lib/*.ts; do
    grep -q "Copyright (c) 2026 Kun Chen" "$file" \
      || fail "$file lost its copyright attribution header"
  done

  grep -q "kunchenguid/dotfiles" "$TITLE_EXT" \
    || fail "terminal-status-title.js lost its provenance header"

  pass "vendored extensions keep their upstream license and attribution"
}

test_runtime_state_stays_unmanaged() {
  # Calm persists on/off to ~/.pi/agent/calm. That is Pi runtime territory:
  # never tracked, never written by Home Manager.
  local nix_sources
  nix_sources=$(cat "$ROOT"/hosts/*.nix "$ROOT"/nix/home.nix "$ROOT"/nix/modules/*.nix)
  assert_not_contains "$nix_sources" '.pi/agent/calm' \
    "Nix manages the Calm runtime state file"
  assert_not_contains "$nix_sources" '.pi/agent/web-search.json' \
    "Nix manages the pi-web-access credential file"

  if git -C "$ROOT" ls-files --error-unmatch config/pi/extensions/calm/calm >/dev/null 2>&1; then
    fail "the Calm state file is tracked in the repository"
  fi

  pass "Calm state and web-search credentials stay untracked and unmanaged"
}

test_nix_wiring() {
  local module
  module=$(cat "$ROOT/nix/modules/pi.nix")

  # Home Manager links the extensions directory as a whole, so vendoring a new
  # extension needs no further declaration.
  assert_contains "$module" '".pi/agent/extensions".source' \
    "nix/modules/pi.nix no longer links ~/.pi/agent/extensions as a directory"

  # Pi rewrites settings.json at runtime, so it must be an out-of-store symlink
  # into the checkout rather than a read-only /nix/store path.
  assert_contains "$module" 'mkOutOfStoreSymlink' \
    "nix/modules/pi.nix no longer links settings.json out of the store"

  # Pi is personal-only; hosts/work.nix asserts this independently.
  assert_contains "$(cat "$ROOT/hosts/personal.nix")" '../nix/modules/pi.nix' \
    "hosts/personal.nix no longer imports the Pi module"

  [ -f "$CALM_DIR/index.ts" ] || fail "calm extension entry point is missing"

  pass "Nix wiring links the extensions directory and keeps settings.json writable"
}

test_javascript_parses() {
  if ! command -v node >/dev/null 2>&1; then
    skip "node not found, cannot parse terminal-status-title.js"
    return 0
  fi
  node --check "$TITLE_EXT" || fail "terminal-status-title.js has a syntax error"
  pass "terminal-status-title.js parses as valid JavaScript"
}

test_calm_typechecks() {
  local pi_dir fixture tmp_root
  if ! command -v tsc >/dev/null 2>&1; then
    skip "tsc not found, skipping the Calm TypeScript check"
    return 0
  fi
  if ! pi_dir=$(pi_package_dir); then
    skip "installed Pi package not found, skipping the Calm TypeScript check"
    return 0
  fi

  tmp_root=$(dotfiles_test_tmproot pi-extensions)
  fixture="$tmp_root/typecheck"
  mkdir -p "$fixture/node_modules/@earendil-works" "$fixture/node_modules/@types"
  cp -R "$CALM_DIR" "$fixture/calm"
  ln -s "$pi_dir" "$fixture/node_modules/@earendil-works/pi-coding-agent"
  ln -s "$pi_dir/node_modules/@earendil-works/pi-tui" "$fixture/node_modules/@earendil-works/pi-tui"
  ln -s "$pi_dir/node_modules/typebox" "$fixture/node_modules/typebox"
  ln -s "$pi_dir/node_modules/@types/node" "$fixture/node_modules/@types/node"
  printf '%s\n' '{"type":"module"}' >"$fixture/package.json"
  cat >"$fixture/tsconfig.json" <<'JSON'
{
  "compilerOptions": {
    "target": "esnext",
    "module": "esnext",
    "moduleResolution": "bundler",
    "lib": ["esnext"],
    "types": ["node"],
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "skipLibCheck": true,
    "verbatimModuleSyntax": true
  },
  "include": ["calm/**/*.ts"]
}
JSON

  # A failure here is the signal that Pi's extension API drifted and the
  # vendored copy needs re-syncing from upstream.
  (cd "$fixture" && tsc -p tsconfig.json) \
    || fail "Calm does not typecheck against the installed Pi ($pi_dir)"

  pass "Calm typechecks strictly against the installed Pi extension API"
}

test_attribution_preserved
test_runtime_state_stays_unmanaged
test_nix_wiring
test_javascript_parses
test_calm_typechecks
