# dotfiles

Declarative Apple Silicon macOS environments powered by Nix flakes, nix-darwin, Home Manager, and a narrow Homebrew layer.

The repository has two complete configurations:

- `personal` is the default for my personal machine
- `work` is the minimal work environment

Both configurations share command-line tools, shell and Git behavior, agent resources, terminal configuration, etc.

## Ownership

Nix owns command-line tools, language runtimes, shell integration, Git configuration, tmux, and stable agent resources.
Homebrew owns GUI applications, fonts, and some exceptions.
Homebrew removes packages that are not declared by the selected profile during activation.

Credentials, work identity, mutable application state, and secrets stay outside Git.
Copy `config/git/work.inc.example` to `~/.config/git/work.inc` on a work machine and fill it in locally.

## Repository structure

```text
.
├── bin/                 # Setup, validation, activation, and update commands
├── config/
│   ├── agents/          # Shared instructions and agent UI configuration
│   ├── git/             # Personal identity, work template, and global ignores
│   ├── herdr/           # Herdr terminal workspace manager
│   ├── pi/              # Pi coding agent keybindings
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
bin/switch personal
bin/update --apply
```

`bin/bootstrap` installs missing prerequisites but never activates a configuration.
`bin/check` runs static checks and builds both profiles from the committed lock file.
`bin/switch` accepts `personal` or `work`, requires a clean checkout, checks both profiles, creates a local Time Machine snapshot, and activates the selected profile.
`bin/update` updates `flake.lock` and keeps the old lock file if either profile fails.

See [setup](docs/setup.md) for a fresh machine and [operations](docs/operations.md) for updates, rollback, and package ownership.
