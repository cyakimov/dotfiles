{ config, pkgs, ... }:
let
  neovim = pkgs.symlinkJoin {
    name = "neovim-with-lazy-nvim";
    paths = [ pkgs.neovim ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --set NVIM_LAZY_PATH ${pkgs.vimPlugins.lazy-nvim}
    '';
  };
in
{
  home.packages = [ neovim ];

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/nvim";
}
