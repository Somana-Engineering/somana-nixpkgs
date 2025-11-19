{ config, lib, pkgs, ... }:

let
  cfg = config.services.sprinter-agent;
  configFile = (pkgs.formats.yaml {}).generate "sprinter-agent-config.yaml" {
    host_registration = {
      sprinter_url = cfg.sprinterUrl;
      host_id = cfg.hostId;
    };
  };
in {
  #### 1) Options for this module
  options.services.sprinter-agent = {
    # turn the service on/off
    enable = lib.mkEnableOption "Sprinter agent";

    # URL the agent should talk to
    sprinterUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:8080";
      description = "Base URL of the Sprinter API used for host registration.";
    };

    # host_id used by the agent
    hostId = lib.mkOption {
      type = lib.types.str;
      default = "0";
      description = "Host ID used for host registration.";
    };
  };

  #### 2) Config + systemd service, only if enabled
  config = lib.mkIf cfg.enable {
    # systemd unit
    systemd.services.sprinter-agent = {
      description = "Sprinter Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        # run as a dynamic user (no hard-coded /home paths needed)
        DynamicUser = true;
        StateDirectory = "sprinter-agent";
        WorkingDirectory = "%S/sprinter-agent";

        # use the packaged binary, point at the Nix-managed config
        # Using the actual file path so systemd restarts the service when config changes
        ExecStart = "${lib.getExe pkgs.sprinter-agent} -config ${configFile}";

        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
