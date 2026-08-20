{
  inputs,
  pkgs,
  ...
}:
with pkgs;
[
  bat
  bun
  buf
  cargo
  clippy
  cmake
  colima
  docker-client
  docker-compose
  eza
  fd
  gh
  go_1_25
  golangci-lint
  gopls
  grpcurl
  hyperfine
  jq
  just
  lazygit
  go-migrate
  mkcert
  # Keep project-local Mise configs working while global tool ownership moves to Nix.
  mise
  ncdu
  neovim
  nodejs_latest
  overmind
  # Nixpkgs' install tests pull unrelated language toolchains that are not runtime dependencies.
  (pre-commit.overridePythonAttrs (_: {
    doCheck = false;
    dontUsePytestCheck = true;
    preCheck = "";
  }))
  protobuf
  protoc-gen-connect-go
  protoc-gen-go
  protoc-gen-go-grpc
  python311
  ripgrep
  ruby_4_0
  rustc
  rustfmt
  shellcheck
  sqlc
  tokei
  tree
  trivy
  uv
  watch
  (pkgs.callPackage ./packages/openspec.nix { src = inputs.openspec; })
  inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent
]
