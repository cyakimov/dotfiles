# dotfiles

Declarative Apple Silicon macOS environments powered by Nix flakes, nix-darwin, Home Manager, and a deliberately narrow Homebrew layer.

This repository is designed to be shared unchanged between Carlos's personal and work Macs.
Machine-local identities, credentials, trust decisions, generated app state, and employer-specific data stay outside Git.

## Safety status

Repository work is safe to review without changing macOS.
Nothing is installed or activated by cloning the repository or running the default forms of its scripts.
Commands that change the machine require an explicit `--apply` flag.

The first activation is intentionally separate from legacy cleanup.
Homebrew cleanup is set to `none`, Nix garbage collection is disabled during migration, and old Mise and Homebrew tools remain available for a 30-day proving period.

Do not merge the migration branch into the live Stow checkout before the first switch succeeds from the isolated worktree.
Merging first would remove source files that active Stow links still need.

Read [the migration runbook](docs/migration.md) before the first activation.
Keep [the recovery runbook](docs/recovery.md) available in another terminal or device.

## Supported environment

- Apple Silicon macOS
- User account `cyakimov`
- Existing `/bin/zsh` login shell
- Official multi-user Nix installation
- Homebrew installed in `/opt/homebrew`

The flake deliberately asserts these assumptions instead of guessing.
Adding Linux, Intel macOS, or a different user should be a separate reviewed change.

## Target repository structure

```text
.
├── AGENTS.md
├── README.md
├── flake.nix
├── flake.lock
├── bin/
│   ├── audit
│   ├── bootstrap
│   ├── build
│   ├── cleanup-legacy
│   ├── purge-legacy
│   ├── rollback
│   ├── switch
│   ├── update
│   └── verify
├── config/
│   ├── agents/
│   ├── git/
│   ├── herdr/
│   ├── pi/
│   ├── shell/
│   ├── terminals/
│   └── tmux/
├── docs/
│   ├── migration.md
│   └── recovery.md
├── migration/
│   ├── adoptable-targets.tsv
│   ├── homebrew-formulae.txt
│   ├── home-manager-targets.txt
│   ├── legacy-links.tsv
│   ├── mise-tools.txt
│   └── replacement-commands.tsv
├── nix/
│   ├── darwin.nix
│   ├── home.nix
│   ├── homebrew.nix
│   ├── packages.nix
│   ├── packages/
│   └── modules/
├── templates/
│   ├── agents/
│   └── git/
└── tests/
```

`flake.lock` is required before building or activating.
On the migration branch it is generated only after Nix is available, then reviewed and committed like source code.

## Ownership model

Nix owns portable command-line tools, language runtimes, shell integration, Git configuration, terminal configuration, tmux, and stable agent resources.

Homebrew owns GUI applications, fonts, and four reviewed macOS exceptions: Herdr, mactop, Mole, and Taproom.
The nix-darwin Homebrew module never removes unlisted packages because `homebrew.onActivation.cleanup` is `none`.
Taproom requires a narrow, explicit Homebrew trust decision documented in the migration runbook.

Mutable Claude, Codex, and Pi settings stay as local regular files.
Sanitized templates seed a fresh machine only when those settings do not already exist.

Work Git identity belongs in `~/.config/git/work.inc`.
Start from `templates/git/work.inc.example` and never commit the resulting local file.

Project-local Mise configuration can coexist during the transition.
The shell ignores the retired global Mise config but still allows project-local `mise.toml` or `.tool-versions` files to activate.

## Normal workflow

Every command below is non-mutating unless it includes `--apply`.

```bash
bin/audit
bin/bootstrap
bin/verify
bin/switch
```

The initial setup sequence is:

```bash
bin/bootstrap --apply
# Open a new shell after Nix installation.
bin/update --apply
git add flake.lock
git commit -m "chore: lock Nix inputs"
bin/build
bin/switch
bin/switch --apply
```

`bin/update --apply` changes only `flake.lock` and proves that the candidate builds.
`bin/build` evaluates and builds without creating a system generation.
`bin/switch` previews home-path migration and activation.
`bin/switch --apply` creates a local Time Machine snapshot, preserves existing settings, and activates only after a successful build.

After a successful personal-Mac canary, wait at least seven days before applying the same committed revision to the work Mac.
Wait at least 30 days on each Mac before running `bin/cleanup-legacy --apply`.

## Updating

Run updates on the personal Mac first.

```bash
bin/update --apply
git diff -- flake.lock
bin/build
```

Commit the reviewed lock-file change before activation.
Do not combine a broad dependency update with unrelated configuration changes.

## What this repository refuses to automate

- Emptying the Trash
- Uninstalling Nix itself
- Removing project-local Mise configuration
- Removing unrelated Homebrew packages or casks
- Trusting third-party Homebrew formulae
- Changing the login shell away from `/bin/zsh`
- Writing work credentials or identities into the public repository
- Running Nix garbage collection during the migration proving period

Those boundaries keep recovery possible and make personal and work machines predictable.
