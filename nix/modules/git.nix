{ pkgs, self, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      color.ui = "auto";
      core = {
        autocrlf = "input";
        excludesFile = "~/.gitignore_global";
      };
      credential = {
        "https://github.com".helper = [
          ""
          "!${pkgs.gh}/bin/gh auth git-credential"
        ];
        "https://gist.github.com".helper = [
          ""
          "!${pkgs.gh}/bin/gh auth git-credential"
        ];
      };
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      push.autoSetupRemote = true;
      url."git@gitlab.com:".insteadOf = "https://gitlab.com";
    };
  };

  home.file.".gitignore_global".source = "${self}/config/git/ignore_global";
}
