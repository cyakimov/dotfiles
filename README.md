# dotfiles

Declarative Apple Silicon macOS environments powered by Nix flakes, nix-darwin, Home Manager, and a narrow Homebrew layer.

The repository has two complete configurations:

- `personal` is the default for Carlos's personal Mac.
- `work` is the minimal work environment.

Both configurations share command-line tools, shell and Git behavior, agent resources, terminal configuration, Bruno, fonts, UnnaturalScrollWheels, Ghostty, and WezTerm.
Everything else is selected by the host profile.

## Ownership

Nix owns command-line tools, language runtimes, shell integration, Git configuration, tmux, and stable agent resources.
Homebrew owns GUI applications, fonts, and the four macOS formula exceptions Herdr, mactop, Mole, and Taproom.
Homebrew removes packages that are not declared by the selected profile during activation.

Credentials, work identity, mutable application state, and secrets stay outside Git.
Copy `config/git/work.inc.example` to `~/.config/git/work.inc` on a work machine and fill it in locally.

## Repository structure

```text
.
├── bin/
│   ├── bootstrap
│   ├── check
│   ├── switch
│   └── update
├── config/
│   ├── agents/
│   ├── git/
│   ├── herdr/
│   ├── pi/
│   ├── shell/
│   ├── terminals/
│   └── tmux/
├── docs/
│   ├── operations.md
│   └── setup.md
├── hosts/
│   ├── personal.nix
│   └── work.nix
├── nix/
│   ├── modules/
│   ├── packages/
│   ├── darwin.nix
│   ├── home.nix
│   ├── homebrew.nix
│   └── packages.nix
├── flake.lock
└── flake.nix
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

## Supported environment

- Apple Silicon macOS
- User account `cyakimov`
- `/bin/zsh` as the login shell
- Multi-user Nix
- Homebrew in `/opt/homebrew`

These constraints are asserted deliberately.
Adding Linux, Intel macOS, or another user should be a separate reviewed change.
