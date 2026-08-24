{ self, ... }:
{
  home.file = {
    ".claude/CLAUDE.md".source = "${self}/AGENTS.md";
    ".claude/statusline-command.sh" = {
      source = "${self}/config/agents/claude-statusline.sh";
      executable = true;
    };
    ".codex/AGENTS.md".source = "${self}/AGENTS.md";
  };
}
