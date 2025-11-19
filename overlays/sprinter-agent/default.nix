{
  buildGoModule,
  dockerTools,
  fetchFromGitHub,
  lib,
}:

buildGoModule (finalAttrs: {
  pname = "sprinter-agent";
  version = "1.0.25";

  src = fetchFromGitHub {
    owner = "somana-engineering";
    repo = "sprinter-agent";
    tag = "v${finalAttrs.version}";
    hash = "";
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
