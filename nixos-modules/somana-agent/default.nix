{ config, lib, pkgs, ... }:

let
  cfg = config.services.somana-agent;
in {
  #### 1) Options for this module
  options.services.somana-agent = {
    # turn the service on/off
    enable = lib.mkEnableOption "Somana agent";

    # URL the agent should talk to
    somanaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:8080";
      description = "Base URL of the Somana API used for host registration.";
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
    # Write /etc/somana-agent/config.yaml from Nix
    environment.etc."somana-agent/config.yaml" = {
      mode = "0644";
      text = ''
        host_registration:
          somana_url: ${cfg.somanaUrl}
          host_id: "${cfg.hostId}"
      '';
    };

    # systemd unit
    systemd.services.somana-agent = {
      description = "Somana Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = [ pkgs.systemd ];

      serviceConfig = {
        # run as a dynamic user (no hard-coded /home paths needed)
        DynamicUser = true;
        StateDirectory = "somana-agent";
        WorkingDirectory = "/var/lib/somana-agent";

        # use the packaged binary, point at the Nix-managed config
        ExecStart = "${lib.getExe pkgs.somana-agent} -config /etc/somana-agent/config.yaml";

        Restart = "always";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
