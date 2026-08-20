# Recovery runbook

The migration is designed so a shell configuration failure is recoverable without uninstalling Nix or reinstalling macOS.

Keep this document available outside the affected terminal during the first activation.

## Fast shell access

Start zsh without user startup files:

```bash
/bin/zsh -f
```

Restore a conservative command path if needed:

```bash
export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

Do not change the login shell during diagnosis.

## Recovery choices

| Symptom | First action | Scope |
| --- | --- | --- |
| New configuration is wrong but `darwin-rebuild` works | `bin/rollback --system` | Preview previous system generation |
| Activation failed after legacy links were moved | Let `bin/switch` finish its automatic file restore | Managed home files only |
| Shell startup is unusable | Run `/bin/zsh -f` | Current terminal only |
| Home Manager links must be bypassed urgently | `bin/rollback --legacy-files` | Preview regular-file restore |
| A cleaned Mise tool is needed | Restore the retired config and payload from the state backup | User tools only |
| A purged Mise payload is needed | Move it back from `~/.Trash` | User tools only |
| macOS itself is unhealthy | Use Time Machine or macOS Recovery | Whole machine |

Every rollback command is a dry run unless it includes `--apply`.

## Roll back a nix-darwin generation

Preview:

```bash
bin/rollback --system
```

Apply:

```bash
bin/rollback --system --apply
```

This invokes `darwin-rebuild switch --rollback`.
It does not restore Stow and does not uninstall packages.

After rollback, open a new terminal and run `bin/audit`.

## Restore pre-migration files

Use this emergency path when Home Manager-created files prevent a usable shell and a system rollback is unavailable or insufficient.

Preview the most recent backup:

```bash
bin/rollback --legacy-files
```

Apply:

```bash
bin/rollback --legacy-files --apply
```

The script replaces only Nix-owned managed symlinks with regular files copied from the migration backup.
It refuses to overwrite foreign symlinks or regular files.
It leaves mutable Claude, Codex, and Pi settings alone because they were already converted to local regular files.

This is an emergency compatibility state, not a final declarative state.
Diagnose the flake and commit a fix before switching again.

## Locate migration backups

The default state root is:

```text
~/.local/state/dotfiles-migration
```

Important records include:

- `current/revision`
- `current/backup`
- `current/activated-at`
- `current/cleaned-at`
- `backups/<timestamp>/files/`
- `backups/<timestamp>/links.tsv`
- `retired/<timestamp>/mise-config.toml`

Do not remove this directory until both Macs have completed the migration and their proving periods.

## Homebrew recovery

Activation never runs `brew bundle cleanup`.
If a cask or reviewed exception fails to install, fix that item separately and rebuild.

Legacy cleanup uses ordinary `brew uninstall` without `--ignore-dependencies`.
Homebrew therefore gets a chance to refuse removals that would break another installed formula.

Reinstall a mistakenly removed legacy formula with `brew install <formula>` while diagnosing.
Do not run broad `brew autoremove` or `brew bundle cleanup` during recovery.

## Mise recovery

Cleanup uses `mise unuse --no-prune` and backs up the global config before editing it.
Installed payloads remain under `~/.local/share/mise` until the later purge.

After purge, the data is under a timestamped `~/.Trash/dotfiles-mise-*` directory.
Move the needed directory back to its original location before emptying the Trash.

## Nix recovery boundaries

Do not run `nix-collect-garbage -d` during the proving period because it can remove rollback generations and cached packages.
Do not manually edit `/run/current-system` or Nix profile symlinks.

Uninstalling Nix is a last-resort operation and is intentionally not automated by this repository.
The official multi-user macOS uninstall procedure changes launch daemons, users, groups, APFS volume configuration, and files under `/etc`.
Follow the documentation for the exact installed Nix version and make a current system backup first.

Removing Nix is not required to roll back Home Manager files or a nix-darwin generation.
