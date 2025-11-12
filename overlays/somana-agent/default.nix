{
  buildGoModule,
  dockerTools,
  fetchFromGitHub,
  lib,
}:

buildGoModule (finalAttrs: {
  pname = "somana-agent";
  version = "1.0.21";

  src = fetchFromGitHub {
    owner = "somana-engineering";
    repo = "somana-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WYVviUP03wGLSmgfxJVGsto4CT1Car8FIVq6yRhDc2I=";
  };

  vendorHash = "sha256-PnG0q/97EnM4leyZ7X6Jswd81l9elz8GTr6B42qRlcM=";

  ldflags = [
    "-s"
    "-w"
  ];

  # TODO(jared): probably a good idea to rename this executable name
  meta.mainProgram = "server";

  passthru.oci = dockerTools.buildImage {
    name = finalAttrs.pname;
    tag = finalAttrs.version;
    config.Entrypoint = [ (lib.getExe finalAttrs.finalPackage) ];
  };
})
