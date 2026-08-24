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

## 4. Configure work identity

Skip this step on a personal-only machine.
The personal profile installs its own identity, so nothing is needed there.

Home Manager owns `~/.config/git/config` as a read-only store symlink and deliberately writes no identity into it.
Create `~/.gitconfig` first, otherwise `git config --global` targets the read-only file and fails.

```bash
touch ~/.gitconfig
git config --global user.name "Your Name"
git config --global user.email you@company.example
```

Git reads `~/.gitconfig` after `~/.config/git/config`, so these values win.
This repository never creates, reads, or validates that file.

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
Check the resolved Git identity with `git config --show-origin --get user.email`.
On the personal profile it comes from `~/.config/git/personal.inc`, and on a work machine from `~/.gitconfig`.
