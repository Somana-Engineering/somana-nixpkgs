{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.somana-agent.enable = lib.mkEnableOption "somana-agent";

  config = lib.mkIf config.services.somana-agent.enable {
    systemd.services.somana-agent = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = lib.getExe pkgs.somana-agent;
      };
    };
  };
}
