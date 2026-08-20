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

## 3. Check both profiles

```bash
bin/check
```

This performs static validation and builds both the personal and work systems without activating either one.

## 4. Configure work identity

Skip this step on a personal-only machine.

```bash
mkdir -p ~/.config/git
cp config/git/work.inc.example ~/.config/git/work.inc
```

Edit the copied file with the employer identity and signing key.
The local file is intentionally not managed by Home Manager.

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

Confirm that the expected terminal applications launch and that Git uses the correct identity inside personal and work repositories.
