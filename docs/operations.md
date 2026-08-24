# Operations

## Profile contents

Both profiles install Bruno, Codex, Hack Nerd Font, JetBrains Mono Nerd Font, Ghostty, OpenLogi, UnnaturalScrollWheels, and WezTerm through Homebrew.

The personal profile additionally installs Herdr, the Pi coding agent, and OpenSpec from their release flakes.
It installs 1Password CLI, AppCleaner, balenaEtcher, ChatGPT, Copilot CLI, Discord, Google Chrome, JetBrains Toolbox, Ollamac, OpenSuperWhisper, Spotify, Transmission, Visual Studio Code, VLC, and Zoom through Homebrew.

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

The repository disables automatic Nix garbage collection and store optimization.
Keep at least one known-good generation and the `/etc/*.before-nix-darwin` files.
Do not empty the Trash containing pre-Nix legacy state until the new configuration has been stable long enough to be trusted.

## Update Neovim plugins

`~/.config/nvim` is a writable symlink to `config/nvim` in this repository, so lazy.nvim edits the checkout directly.

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

## Secrets and mutable state

Authentication, SSH keys, application databases, histories, caches, and employer configuration are not managed here.
Home Manager manages only the stable files explicitly declared under `nix/modules/`.

Git follows that rule.
`hosts/personal.nix` imports `nix/modules/git.nix`, so Git behavior and the personal identity exist only on that profile.
The work profile writes nothing Git-config-shaped, leaving the MDM-managed `~/.config/git/config` untouched.
Work keeps the `git-lfs` binary from `nix/packages.nix`, but registers no LFS filters; run `git lfs install` locally if a repository needs them.
