inputs:

{
  default = final: prev: {
    somana-agent = final.callPackage ./somana-agent { };
  };
}
