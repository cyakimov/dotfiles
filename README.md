<h1 align="center">dotfiles</h1>

Minimal, versioned dotfiles for development environments. Each top‑level folder is a module (e.g., `git`, `zsh`, `mise`) whose contents are symlinked into place using GNU Stow.

## Prerequisites
- GNU Stow installed (`stow` command in your PATH)

Install Stow:
- macOS (Homebrew): `brew install stow`
- Debian/Ubuntu: `sudo apt-get install stow`
- Fedora: `sudo dnf install stow`

## Quick start
```bash
# clone
git clone https://github.com/cyakimov/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 1) Preview (no changes):
stow -n -v git            # shows what would be linked

# 2) Apply to $HOME (default target):
stow git                  # link git configs into ~

# 3) Unstow (remove created symlinks):
stow -D git

# 4) Restow (refresh/repair links after changes or moves):
stow -R git

# XDG configs need no special flags: the package already contains .config/
stow mise                 # links ~/.config/mise
```

Notes:
- Run Stow from the repository root.
- Each module mirrors the target directory structure, including the `.config/` level where applicable. For example, files in `git/` map to `~/.gitconfig`, `~/.gitignore_global`, etc. Files in `zsh/` map to `~/.zshrc`, `~/.zsh_aliases`, and `ghostty/.config/ghostty/config` maps to `~/.config/ghostty/config`.
- Use `stow -n` (dry run) first to avoid surprises.

## Handling existing files (conflicts)
If Stow reports conflicts (because a regular file already exists where a symlink would go):
- Back up or remove the existing file, then restow: `mv ~/.gitconfig ~/.gitconfig.bak && stow -R git`
- Advanced: `stow --adopt git` can “adopt” existing files into the repo by turning them into symlinks. Use with caution and review changes.

## Verify
- List links: `ls -l ~/.gitconfig ~/.gitignore_global`
- Show where a symlink points: `readlink -f ~/.gitconfig` (Linux) or `greadlink -f ~/.gitconfig` (macOS with coreutils)

## Git profiles in this repo
This repo includes two example Git profiles you can opt into:
- `git/git-personal.conf`
- `git/git-work.conf`

You can include one (or both conditionally) from your `~/.gitconfig` using Git’s includeIf rules. Example patterns:

```
# ~/.gitconfig
[include]
path = ~/.dotfiles/git/git-personal.conf

# Optionally include work settings only in specific directories
[includeIf "gitdir:~/work/"]
path = ~/.dotfiles/git/git-work.conf
```

Then stow the `git` module from this repository so that global paths like `~/.gitignore_global` are linked into place.

## macOS defaults
Some settings are system preferences applied via `defaults` rather than symlinked files. Apply them with:

```bash
# Apply macOS system defaults (key repeat, etc.)
./macos/defaults.sh
```

The script is idempotent and macOS-only. A logout/login (or restarting affected apps) may be needed for everything to take effect.

## Modules
- `claude` - Claude Code instructions, settings, and statusline script (`~/.claude/`)
- `ghostty` - Ghostty terminal config (`~/.config/ghostty/`)
- `git` - gitconfig fragments and global gitignore
- `mise` - tool versions/config (`~/.config/mise/`)
- `wezterm` - WezTerm terminal config (`~/.config/wezterm/`)
- `zsh` - shell config and aliases
- `macos` - system preferences applied via `defaults`; not stowed, run `./macos/defaults.sh` directly

## Troubleshooting
- “WARNING! stowing may cause conflicts”: run `stow -n -v <module>` to preview and resolve by moving existing files aside or using `--adopt` carefully.
- Nothing happened? Ensure you’re running `stow` from the repo root and the module directory exists.
- Targeting another home: use `-t` to specify the destination directory.

## License
Personal use; feel free to reference, but review before adopting as-is.
