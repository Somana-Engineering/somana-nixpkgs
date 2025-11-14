inputs:

{
  default = final: prev: {
    sprinter-agent = final.callPackage ./sprinter-agent { };
  };
}
