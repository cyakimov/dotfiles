#!/usr/bin/env bash
#
# macOS system defaults.
#
# Idempotent: re-running just overwrites the values, so it is safe to run
# repeatedly. Group new tweaks under their own section header below.
#
# Usage (from the repo root):
#   ./macos/defaults.sh

set -euo pipefail

# Only run on macOS; on other platforms there is nothing to do.
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Not macOS - nothing to do."
    exit 0
fi

# ===============================================
# KEYBOARD
# ===============================================
# Disable the press-and-hold accent popup so holding a key repeats it instead.
defaults write -g ApplePressAndHoldEnabled -bool false
# Delay before a held key starts repeating (lower is faster; ~180ms).
defaults write -g InitialKeyRepeat -int 12
# Interval between repeats once started (lower is faster; ~30ms).
defaults write -g KeyRepeat -int 2

echo "macOS defaults applied."
echo "Note: some settings (e.g. ApplePressAndHoldEnabled) only take full effect"
echo "after logging out and back in, or restarting the affected apps."
