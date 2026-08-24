# dotfiles

Declarative Apple Silicon macOS environments powered by Nix flakes, nix-darwin, Home Manager, and a narrow Homebrew layer.

The repository has two complete configurations:

- `personal` is the default for my personal machine
- `work` is the minimal work environment

Both configurations share command-line tools, shell and Git behavior, agent resources, terminal configuration, etc.

## Ownership

Nix owns command-line tools, language runtimes, shell integration, Git configuration, tmux, Neovim, and stable agent resources.
Homebrew owns GUI applications, fonts, and some exceptions.
Homebrew removes packages that are not declared by the selected profile during activation.

Credentials, work identity, mutable application state, and secrets stay outside Git.
Nix manages Git behavior on both profiles, personal Git identity only on `personal`, and work Git identity not at all.
On a work machine the identity lives in `~/.gitconfig`, which this repository never creates, reads, or validates.

`config/nvim` is the one directory linked into place as a writable symlink rather than a read-only store copy.
lazy.nvim needs to write `lazy-lock.json` there, so plugin updates land as ordinary changes in this checkout and must be committed before `bin/switch` will run.

## Repository structure

```text
.
├── bin/                 # Setup, validation, activation, and update commands
├── config/
│   ├── agents/          # Shared instructions and agent UI configuration
│   ├── git/             # Personal identity and global ignores
│   ├── herdr/           # Herdr terminal workspace manager
│   ├── pi/              # Pi coding agent keybindings, personal profile only
│   ├── nvim/            # Neovim configuration built on LazyVim
│   ├── shell/           # Aliases and Powerlevel10k configuration
│   ├── terminals/       # Ghostty and WezTerm configuration
│   └── tmux/            # tmux configuration
├── docs/                # Setup and operational runbooks
├── hosts/               # Personal and work profile differences
├── nix/
│   ├── modules/         # Shared Home Manager modules
│   └── packages/        # Custom Nix package definitions
├── flake.nix            # Flake inputs and profile outputs
└── flake.lock           # Pinned dependency revisions
```

## Commands

```bash
bin/bootstrap --apply
bin/check
bin/check work
bin/switch personal
bin/update --apply
```

`bin/bootstrap` installs missing prerequisites but never activates a configuration.
`bin/check` runs static checks and builds both profiles from the committed lock file.
Pass `personal` or `work` to build only that profile and the static checks.
`bin/switch` accepts `personal` or `work`, requires a clean checkout, checks only the selected profile, creates a local Time Machine snapshot, and activates it.
`bin/update` updates `flake.lock` and keeps the old lock file if either profile fails.

## Migrate the work Mac

The temporary migration helper stages a pre-Nix work laptop safely.

```bash
bin/migrate-work audit
bin/migrate-work prepare
bin/migrate-work activate
# Open a new terminal.
bin/migrate-work verify
bin/migrate-work cleanup
```

Run `bin/migrate-work help` before starting.
The helper keeps its inventory and recoverable backups under `~/.local/state/dotfiles-work-migration`.

See [setup](docs/setup.md) for a fresh machine and [operations](docs/operations.md) for updates, rollback, and package ownership.
