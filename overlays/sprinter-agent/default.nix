{
  buildGoModule,
  dockerTools,
  fetchFromGitHub,
  fetchurl,
  lib,
  pkgs,
}:

let
  # OpenAPI version from the Makefile
  openapiVersion = "v1.0.37";
  
  # Download the OpenAPI specification
  openapiSpec = fetchurl {
    url = "https://github.com/miku-kookie/somana/releases/download/${openapiVersion}/openapi.yaml";
    hash = "sha256-PUzKEqfeIV9oC4xNKAQJQ3sFiXi0FuzYQUhd09XRm7w="; 
  };
in

buildGoModule (finalAttrs: {
  pname = "sprinter-agent";
  version = "1.0.41";

  src = fetchFromGitHub {
    owner = "somana-engineering";
    repo = "sprinter-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-4JpEnBs2jB4ZfwEJl6eoX5D9xSyQ9cEivryJr7rUBZA=";
  };

  vendorHash = "sha256-JbfAQl9y/iVt2Id231Ufh7iYX0ViEzgAhP4DAFicmzE=";

  nativeBuildInputs = [ pkgs.oapi-codegen ];

  # Pre-populate the OpenAPI spec file, then let Make handle code generation
  # Make will see api/openapi.yaml exists and skip downloading it
  preBuild = ''
    echo "Pre-populating OpenAPI specification for Make..."
    mkdir -p api
    cp ${openapiSpec} api/openapi.yaml
    
    echo "Running make generate (will use existing api/openapi.yaml)..."
    # Set OAPI_CODEGEN environment variable so Make can find it
    export OAPI_CODEGEN=${lib.getExe pkgs.oapi-codegen}
    make generate
  '';

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
