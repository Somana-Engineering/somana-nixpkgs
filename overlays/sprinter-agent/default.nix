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

  # Add oapi-codegen to nativeBuildInputs so it's available during build
  nativeBuildInputs = [ oapi-codegen ];

  # Generate code from OpenAPI spec before building
  preBuild = ''
    echo "Downloading OpenAPI specification..."
    mkdir -p api
    cp ${openapiSpec} api/openapi.yaml
    
    echo "Generating code from OpenAPI spec..."
    mkdir -p internal/generated
    
    # Generate server code
    ${lib.getExe oapi-codegen} \
      -package generated \
      -generate gin-server \
      api/openapi.yaml > internal/generated/server.go
    
    # Generate client and types code
    ${lib.getExe oapi-codegen} \
      -package generated \
      -generate types,client \
      api/openapi.yaml > internal/generated/client.go
    
    echo "Code generation complete"
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
