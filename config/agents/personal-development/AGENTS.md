# Personal workspace worktrees

These instructions apply to repositories under `~/Development/Personal`.

- Use `treepi` to manage worktrees for repository work. Do not create or manage project worktrees with raw `git worktree` commands.
- Before implementing a plan, run `treepi ls` from the target repository, create a dedicated worktree with `treepi new <task-slug>`, locate it with `treepi where <task-slug>`, and make all implementation changes there. Keep the primary checkout untouched.
- Use Treepi commands such as `sync`, `merge`, `rm`, and `undo` for later worktree lifecycle operations, subject to existing repository instructions and user authorization.
- If Treepi is unavailable or cannot manage the repository, stop before implementation and report the blocker. Do not fall back to raw Git worktree commands or edit the primary checkout.
