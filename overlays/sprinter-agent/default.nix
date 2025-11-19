{
  buildGoModule,
  dockerTools,
  fetchFromGitHub,
  lib,
}:

buildGoModule (finalAttrs: {
  pname = "sprinter-agent";
  version = "1.0.34";

  src = fetchFromGitHub {
    owner = "somana-engineering";
    repo = "sprinter-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-CnVFJokFSPlaTbu/L0506PdGS1kRkxncLuwwpXhdYjs=";
  };

  vendorHash = "sha256-JbfAQl9y/iVt2Id231Ufh7iYX0ViEzgAhP4DAFicmzE=";

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
