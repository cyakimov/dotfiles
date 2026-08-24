{ pkgs, ... }:
with pkgs;
[
  air
  atlas
  bat
  bun
  buf
  cargo
  clippy
  cmake
  civo
  claude-code
  colima
  docker-client
  docker-compose
  eza
  eas-cli
  esp-generate
  espflash
  fastfetch
  fd
  gh
  git-lfs
  go_1_26
  go-tools
  golangci-lint
  gopls
  grpcurl
  gws
  htop
  hyperfine
  jq
  just
  lazygit
  go-migrate
  mkcert
  ncdu
  neovim
  nilaway
  nmap
  nodejs_latest
  overmind
  oapi-codegen
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
  sipcalc
  sqlc
  supabase-cli
  templ
  tokei
  tree
  tree-sitter
  trivy
  turso-cli
  uv
  watch
  wire
  xk6
  yazi
]
