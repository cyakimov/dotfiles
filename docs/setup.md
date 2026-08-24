# Setup

This setup starts from Nix and Homebrew as the only package managers owned by the repository.
It does not require Stow or Mise.

## 1. Clone and inspect

Clone the repository into `~/dotfiles`, select the intended revision, and inspect `flake.lock` before activation.

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
git status --short
```

## 2. Install prerequisites

Preview the bootstrap first.

```bash
bin/bootstrap
bin/bootstrap --apply
```

Open a new terminal after Nix installation.

## 3. Check the target profile

```bash
bin/check personal
```

Use `bin/check work` on a work Mac.
Running `bin/check` without an argument performs static validation and builds both systems.

## 4. Git configuration

Nothing to do on either machine.

The personal profile installs its own identity and Git behavior automatically.
The work profile writes no Git configuration, because that machine's Git configuration is managed by MDM.
This repository never creates, reads, or validates it.

## 5. Activate one profile

```bash
bin/switch personal
```

Use `bin/switch work` on a work Mac.
Activation requires a clean checkout and creates a local Time Machine snapshot immediately before changing the system.
Homebrew removes installed packages and applications that are not declared by the selected profile.

Open a new terminal when activation completes.

## 6. Verify

```bash
darwin-rebuild --list-generations
git config --show-origin --get user.email
command -v nix gh go node rustc
```

Confirm that the expected terminal applications launch.
On the personal profile, check the resolved Git identity with `git config --show-origin --get user.email`.
It must come from `~/.config/git/personal.inc`.
