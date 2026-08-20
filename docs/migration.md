# Migration runbook

This runbook migrates the existing Stow, Brewfile, and global Mise setup to nix-darwin and Home Manager without coupling activation to cleanup.

The migration branch is `feat/nix-darwin-migration`.
Prepare and review it in a separate worktree so edits cannot invalidate live Stow links before the switch.

## Non-negotiable safety invariants

- Never edit or remove the legacy Stow source files from the live checkout before migration.
- Never merge the migration branch into the live legacy checkout before the first switch succeeds.
- Never activate an uncommitted or dirty flake.
- Never activate without a reviewed `flake.lock`.
- Never use Homebrew cleanup during nix-darwin activation.
- Never use Home Manager `force` or overwrite existing foreign paths.
- Never uninstall legacy tools during the first activation.
- Never run Nix garbage collection during the proving period.
- Never purge Mise data while any project-local Mise-compatible configuration remains.
- Never trial the work Mac before the same revision survives the personal-Mac canary.

## Phase 0: review only

Run the repository checks from the isolated migration worktree.

```bash
bin/audit
bin/verify
bin/bootstrap
bin/switch --legacy-repo ~/dotfiles
```

The commands above do not install software, unlink files, activate a generation, or uninstall anything.

Review the ownership boundaries in `nix/packages.nix`, `nix/homebrew.nix`, and `migration/replacement-commands.tsv`.
Review `migration/legacy-links.tsv` against the actual symlinks in the home directory.

## Phase 1: install prerequisites without activation

Confirm that Time Machine is configured and that an external backup is current.
Confirm that at least 20 GiB of disk space is available.

Run:

```bash
bin/bootstrap --apply
```

The bootstrap script uses the official Homebrew installer only when Homebrew is absent.
It uses the official multi-user Nix installer only when Nix is absent.
It does not invoke nix-darwin.

Open a new terminal after Nix installation.
Keep `/bin/zsh` as the login shell.

Taproom is the only package sourced from a third-party Homebrew tap.
Tap and inspect its formula, then grant trust to that formula only:

```bash
brew tap gromgit/brewtils
less "$(brew --repository gromgit/brewtils)/Formula/taproom.rb"
brew trust --formula gromgit/brewtils/taproom
brew trust --json=v1
```

The repository deliberately does not automate this trust decision.
Both `bin/audit` and `bin/switch --apply` block until Taproom is trusted either by exact formula or by its containing tap.

## Phase 2: lock and build

Generate the initial lock file and build the complete candidate:

```bash
bin/update --apply
git diff -- flake.lock
git add flake.lock
git commit -m "chore: lock Nix inputs"
bin/build
```

The build must complete before any home link is touched.
Do not work around evaluation failures by deleting packages from the migration ledger without documenting the ownership change.

OpenSpec source comes from its official upstream flake.
Its local package expression uses the security-supported pnpm from the pinned Nixpkgs because OpenSpec 1.10.0's upstream flake still hardcodes an insecure pnpm 9 release.
Remove the local expression once upstream moves to a supported pnpm release.
Pi currently comes from the pinned `lukasl-dev/pi.nix` packaging flake because the Pi project does not publish an official Nix flake.
Treat replacement of that community input with an official upstream package as future maintenance work.

## Phase 3: preview the first switch

From the clean, committed migration checkout, run:

```bash
bin/switch --legacy-repo ~/dotfiles
```

The preview validates every legacy link against the expected source checkout.
It refuses dangling links, foreign links, and unmanaged regular files at Home Manager targets.
It explicitly adopts the existing empty `~/.zshenv`, preserving it in the migration backup before Home Manager replaces it.
Any non-empty or linked `~/.zshenv` is refused.

The preview also reports existing `/etc/bashrc` and `/etc/zshrc` paths unless they are already owned by Nix.
The official multi-user Nix installer adds its daemon profile stanza to the stock macOS versions of these files.
Inspect them for any additional customization before preserving them for nix-darwin:

```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

These commands retain the complete original files and match nix-darwin's expected backup names.
The apply form refuses to build, snapshot, or change home paths while either conflict remains.
It also refuses when both an original path and its `.before-nix-darwin` backup already exist.

The existing `~/.config/git/ignore` is not managed or removed.
Git continues to use the declarative `~/.gitignore_global`, which avoids overwriting unrelated XDG state.

Mutable Claude, Codex, and Pi settings are not Home Manager targets.
During the real switch, a legacy symlink at one of those paths becomes a local regular file with the same contents.

The old global Mise config is also preserved as a regular file.
The new session sets `MISE_GLOBAL_CONFIG_FILE` to a separate empty location so global Mise tools stop shadowing their Nix replacements.
Project-local Mise activation remains available.

## Phase 4: activate the personal Mac canary

Keep the live legacy checkout on its current branch and commit.
Run the switch from the isolated migration worktree while the live checkout continues to provide every existing Stow target.
Merging the migration branch first would delete those legacy source paths and could immediately leave dangling home-directory links.

Close or save work in shells and applications that may rewrite managed configuration.
Keep a second terminal open.
In that terminal, verify that `/bin/zsh -f` starts successfully.

Run:

```bash
bin/switch --apply --legacy-repo ~/dotfiles
```

The script performs these actions in order:

1. Revalidates every migration target.
2. Refuses first-activation `/etc` conflicts before making any change.
3. Refuses a dirty checkout or missing lock file.
4. Builds the candidate without activation.
5. Creates a local Time Machine snapshot.
6. Copies legacy file contents and link metadata into a timestamped state backup.
7. Converts mutable settings from repository symlinks to local regular files.
8. Removes only verified legacy links that Home Manager must replace.
9. Activates the reviewed flake.
10. Restores the exact recorded direct and folded legacy link topology automatically if activation fails.
11. Records the revision, activation time, configuration name, and backup path.

The state directory is `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-migration`.
Do not delete it during the migration.

The first activation leaves every legacy Homebrew formula and every Mise installation in place.
Homebrew casks are installed if missing but never cleaned up automatically.

Only after the switch succeeds and `bin/audit` reports a healthy declarative environment may the migration branch be merged into the live checkout.

## Phase 5: verify the personal Mac

Open a new terminal and run:

```bash
bin/audit
type -a git node go python3 ruby rustc pi openspec
docker compose version
git config --show-origin --list
```

Confirm that portable commands resolve through `/nix/store`.
Confirm that Herdr, mactop, Mole, and Taproom resolve through `/opt/homebrew`.
Confirm that Claude, Codex, and Pi retain authentication and local preferences.
Confirm that Git signing works in a disposable personal repository.
On the work Mac, create `~/.config/git/work.inc` before testing a work repository.

Exercise active projects for at least seven days on the personal Mac.
Do not use the presence of a successful shell alone as proof that language runtimes and project workflows are healthy.

## Phase 6: activate the work Mac

Use the exact commit and `flake.lock` proven on the personal Mac.
Repeat the audit, build, preview, and switch steps.

Keep work-only data outside the repository:

- `~/.config/git/work.inc`
- SSH keys and `allowed_signers`
- 1Password state
- Claude, Codex, and Pi mutable settings
- Employer certificates, registries, VPN state, and internal endpoints

If the work machine needs a package not appropriate for the personal machine, add a host module in a reviewed follow-up instead of committing company details.

## Phase 7: clean managed legacy tools

Cleanup remains locked until 30 days after activation on each Mac.

Preview it first:

```bash
bin/cleanup-legacy
```

Apply only after every replacement in `migration/replacement-commands.tsv` resolves through its expected provider:

```bash
bin/cleanup-legacy --apply
```

The cleanup script removes only entries declared by the old global Mise config and formulae declared by the old Brewfile that now have Nix replacements.
It calls `mise unuse --no-prune`, so installed payloads remain recoverable for another 30 days.
It leaves all casks and unrelated Homebrew formulae untouched.

Mise itself is supplied by Nix during the compatibility period, so the old Homebrew formula can be removed safely.
If a project-local `mise.toml`, `.mise.toml`, or `.tool-versions` file exists, all Mise data is preserved.

## Phase 8: retire residual Mise data

The purge remains locked for another 30 days after cleanup.
It refuses to run while any project-local Mise-compatible configuration is found.

```bash
bin/purge-legacy
bin/purge-legacy --apply
```

The apply form moves Mise data, state, caches, and configuration to a timestamped directory in `~/.Trash`.
It does not permanently delete them.
Emptying the Trash remains a manual decision.
After the purge proves unnecessary, remove the temporary `mise` compatibility package from `nix/packages.nix` in a normal reviewed update.

## Ongoing maintenance

Update inputs on the personal Mac and inspect `flake.lock` changes before building.
Promote the same commit to the work Mac only after the personal canary succeeds.

Keep `homebrew.onActivation.cleanup = "none"` unless the repository eventually becomes a complete inventory of every Homebrew item on both machines.
Keep Nix garbage collection manual until rollback generations are no longer needed.
