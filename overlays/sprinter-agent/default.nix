{
  buildGoModule,
  dockerTools,
  fetchFromGitHub,
  lib,
  make,
}:

buildGoModule (finalAttrs: {
  pname = "sprinter-agent";
  version = "1.0.25";

  src = fetchFromGitHub {
    owner = "somana-engineering";
    repo = "sprinter-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qRkHkZjUdg8sX+cU9FJP6jI/G00K58VFACMo33tRK/w=";
  };

  vendorHash = "sha256-YLBgTvkm33tLWwlYpB+ShW6XHcW/MqIquXlO6FIgiEU=";

  nativeBuildInputs = [ make ];

  # Override buildPhase to use 'make build' instead of default go build
  buildPhase = ''
    runHook preBuild
    make build
    runHook postBuild
  '';

  # TODO(jared): probably a good idea to rename this executable name
  meta.mainProgram = "server";

  passthru.oci = dockerTools.buildImage {
    name = finalAttrs.pname;
    tag = finalAttrs.version;
    config.Entrypoint = [ (lib.getExe finalAttrs.finalPackage) ];
  };
})
