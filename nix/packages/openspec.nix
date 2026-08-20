{
  fetchPnpmDeps,
  installShellFiles,
  lib,
  nodejs_22,
  pnpm_11,
  pnpmConfigHook,
  src,
  stdenvNoCC,
}:
let
  packageJson = builtins.fromJSON (builtins.readFile "${src}/package.json");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "openspec";
  inherit (packageJson) version;

  inherit src;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-+4UKRZjUM08hitESWF8tBW7tmyRkbYKED59xIVjVrjE=";
  };

  nativeBuildInputs = [
    installShellFiles
    nodejs_22
    pnpm_11
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/openspec
    substituteInPlace bin/openspec.js \
      --replace-fail '#!/usr/bin/env node' '#!${nodejs_22}/bin/node' \
      --replace-fail "../dist" "$out/lib/openspec/dist"
    install -Dm755 bin/openspec.js $out/bin/openspec
    cp -r dist schemas node_modules package.json $out/lib/openspec/

    runHook postInstall
  '';

  postInstall = ''
    installShellCompletion --cmd openspec \
      --bash <($out/bin/openspec completion generate bash) \
      --fish <($out/bin/openspec completion generate fish) \
      --zsh <($out/bin/openspec completion generate zsh)
  '';

  meta = {
    description = "AI-native system for spec-driven development";
    homepage = "https://github.com/Fission-AI/OpenSpec";
    license = lib.licenses.mit;
    mainProgram = "openspec";
    platforms = lib.platforms.all;
  };
})
