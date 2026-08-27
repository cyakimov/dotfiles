{
  description = "Carlos's macOS configuration with nix-darwin and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr.url = "github:herdrdev/herdr/v0.8.2";

    openspec = {
      url = "github:Fission-AI/OpenSpec";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hunk.url = "github:modem-dev/hunk";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      mkDarwinConfiguration =
        hostModule:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs self; };
          modules = [
            ./nix/darwin.nix
            hostModule
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs self; };
                users.cyakimov = import ./nix/home.nix;
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        personal = mkDarwinConfiguration ./hosts/personal.nix;
        work = mkDarwinConfiguration ./hosts/work.nix;
      };

      formatter.${system} = pkgs.nixfmt;

      packages.${system}.openspec = pkgs.callPackage ./nix/packages/openspec.nix {
        src = inputs.openspec;
      };

      checks.${system} = {
        personal = self.darwinConfigurations.personal.system;
        work = self.darwinConfigurations.work.system;
        static =
          pkgs.runCommand "dotfiles-static-checks"
            {
              nativeBuildInputs = with pkgs; [
                bash
                deadnix
                git
                jq
                nixfmt
                python3
                shellcheck
                statix
              ];
            }
            ''
              cp -R ${self} source
              chmod -R u+w source
              find source/bin -type f -print0 | xargs -0 -n1 bash -n
              shellcheck source/bin/* source/config/agents/claude-statusline.sh
              find source -type f -name '*.nix' -exec nixfmt --check {} +
              deadnix --fail source
              statix check source
              find source/config -type f -name '*.json' -print0 | xargs -0 -n1 jq empty
              find source/config -type f -name '*.toml' -print0 | \
                xargs -0 -n1 python3 -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())'
              touch $out
            '';
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          deadnix
          nixfmt
          shellcheck
          statix
        ];
      };
    };
}
