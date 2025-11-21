{
  buildGoModule,
  dockerTools,
  fetchFromGitHub,
  fetchurl,
  lib,
}:

let
  # OpenAPI version from the Makefile
  openapiVersion = "v1.0.37";
  
  # Download the OpenAPI specification
  openapiSpec = fetchurl {
    url = "https://github.com/miku-kookie/somana/releases/download/${openapiVersion}/openapi.yaml";
    hash = "sha256-0000000000000000000000000000000000000000000000000000"; # Update this after first build
  };

  # Build oapi-codegen tool for code generation
  oapi-codegen = buildGoModule {
    pname = "oapi-codegen";
    version = "2.3.0";
    src = fetchFromGitHub {
      owner = "oapi-codegen";
      repo = "oapi-codegen";
      rev = "v2.3.0";
      hash = "sha256-0000000000000000000000000000000000000000000000000000"; # Update this after first build
    };
    vendorHash = "sha256-0000000000000000000000000000000000000000000000000000"; # Update this after first build
    subPackages = [ "cmd/oapi-codegen" ];
  };
in

buildGoModule (finalAttrs: {
  pname = "sprinter-agent";
  version = "1.0.40";

  src = fetchFromGitHub {
    owner = "somana-engineering";
    repo = "sprinter-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-r1BiQiB+Neav/efkgRuzDwGeexartiAjsnoKnLx+Dmo=";
  };

  vendorHash = "sha256-JbfAQl9y/iVt2Id231Ufh7iYX0ViEzgAhP4DAFicmzE=";

  # Add oapi-codegen and make to nativeBuildInputs
  nativeBuildInputs = [ oapi-codegen ];

  # Pre-populate the OpenAPI spec file, then let Make handle code generation
  # Make will see api/openapi.yaml exists and skip downloading it
  preBuild = ''
    echo "Pre-populating OpenAPI specification for Make..."
    mkdir -p api
    cp ${openapiSpec} api/openapi.yaml
    
    echo "Running make generate (will use existing api/openapi.yaml)..."
    # Set OAPI_CODEGEN environment variable so Make can find it
    export OAPI_CODEGEN=${lib.getExe oapi-codegen}
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
