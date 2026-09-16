# Operations

## Profile contents

Both profiles install Bruno, Claude Code, Codex, Hack Nerd Font, JetBrains Mono Nerd Font, Ghostty, OpenLogi, UnnaturalScrollWheels, and WezTerm through Homebrew.

The personal profile additionally installs Herdr and OpenSpec from their release flakes.
It installs 1Password CLI, AppCleaner, balenaEtcher, ChatGPT, Copilot CLI, Discord, Google Chrome, JetBrains Toolbox, Ollamac, OpenSuperWhisper, the Pi coding agent, Spotify, Transmission, Visual Studio Code, VLC, and Zoom through Homebrew.

The work profile declares no additional applications.
Pi, Herdr, and OpenSpec are not available there, where Claude Code and Codex are the permitted agents.
Slack is not declared in either profile.

The shared Homebrew formula exceptions are mactop and Mole.
All other command-line tools belong in `nix/packages.nix`.

## Update dependencies

Run updates on the personal Mac first.

```bash
bin/update --apply
git diff -- flake.lock
git add flake.lock
git commit -m "chore: update Nix inputs"
bin/switch personal
```

`bin/update` refuses a dirty checkout.
If either profile fails to build, it restores the previous lock file.

## Change packages

Put shared GUI applications in `nix/homebrew.nix`.
Put profile-specific GUI applications in the matching file under `hosts/`.
Put portable command-line tools in `nix/packages.nix`.

Before activation, review the exact Homebrew removal set with a generated Brewfile.

```bash
nix eval --raw .#darwinConfigurations.personal.config.homebrew.brewfile > /tmp/dotfiles.Brewfile
brew bundle cleanup --file=/tmp/dotfiles.Brewfile
```

Use the `work` output when reviewing a work Mac.
The cleanup command above is a preview because it omits `--force`.
The nix-darwin activation applies the declared `uninstall` cleanup mode without using Homebrew's destructive `zap` option.

## Roll back

List the retained system generations.

```bash
darwin-rebuild --list-generations
```

Roll back to the previous generation.

```bash
sudo darwin-rebuild switch --rollback
```

To select a specific retained generation, use its generation number.

```bash
sudo darwin-rebuild switch --switch-generation <number>
```

The repository enables automatic Nix garbage collection, pruning generations and their store paths older than 30 days; store optimization stays disabled.
Keep at least one known-good generation younger than that window, along with the `/etc/*.before-nix-darwin` files.

## Update Neovim plugins

`~/.config/nvim` is a writable symlink to `config/nvim` in this repository, so lazy.nvim edits the checkout directly.
Nix installs lazy.nvim itself and updates it through `flake.lock` and profile activation.
All other Neovim plugins remain managed by lazy.nvim.

```bash
nvim  # then :Lazy update
git diff -- config/nvim/lazy-lock.json
git add config/nvim/lazy-lock.json
git commit -m "chore: update Neovim plugins"
```

Committing is not optional housekeeping.
`bin/switch` and `bin/update` both refuse a dirty checkout, so an uncommitted lockfile blocks the next activation.

Enabling an extra with `:LazyExtras` rewrites `config/nvim/lazyvim.json`, which is committed the same way.
The plugin payload under `~/.local/share/nvim`, along with `~/.local/state/nvim` and `~/.cache/nvim`, is regenerable runtime state and stays unmanaged.

## Update Pi configuration

`~/.pi/agent/settings.json` is a writable symlink to `config/pi/settings.json`, following the same pattern as Neovim above.
Pi rewrites that file whenever you change theme or run `/install`, so the edit lands in the checkout and is committed like any other change.

```bash
git diff -- config/pi/settings.json
git add config/pi/settings.json
git commit -m "chore: update Pi settings"
```

Extension versions in `packages` are pinned deliberately.
Bump them in the same commit as any behavior change they cause.

`~/.pi/agent/extensions` is a read-only store symlink to `config/pi/extensions`, which holds two vendored extensions.
`terminal-status-title.js` shows agent state in the terminal tab title.
`calm/` is an opt-in `/calm` toggle that hides collapsed thinking and built-in tool shells from the transcript; it changes presentation only and defaults to off.

Both are vendored from an upstream repository rather than installed from npm, so they need manual re-syncing.
`tests/pi-extensions.test.sh` typechecks `calm/` against the installed Pi and is the signal that Pi's extension API drifted.
The flake static check runs that suite but skips the typecheck, which needs Pi installed; run it directly to exercise everything.

```bash
bash tests/pi-extensions.test.sh
```

`calm/index.ts` carries one local delta from upstream, marked in a comment, adapting the `onTerminalInput` handler to the Pi 0.84 signature.
Preserve it, or re-apply it, when re-syncing.

## Secrets and mutable state

Authentication, SSH keys, application databases, histories, caches, and employer configuration are not managed here.
Home Manager manages only the stable files explicitly declared under `nix/modules/`.

Git follows that rule.
`hosts/personal.nix` imports `nix/modules/git.nix`, so Git behavior and the personal identity exist only on that profile.
The work profile writes nothing Git-config-shaped, leaving the MDM-managed `~/.config/git/config` untouched.
Work keeps the `git-lfs` binary from `nix/packages.nix`, but registers no LFS filters; run `git lfs install` locally if a repository needs them.

Pi follows that rule too.
`~/.pi/agent/calm` records the Calm toggle and `~/.pi/agent/web-search.json` would hold search provider API keys.
Both are Pi runtime state, deliberately untracked and unmanaged; `pi-web-access` needs no key because it reuses the Codex login.
