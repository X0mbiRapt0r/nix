{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.xombiraptor.services.cloudflareTunnel;
in
{
  options.xombiraptor.services.cloudflareTunnel = {
    enable = lib.mkEnableOption "the host's remotely managed Cloudflare Tunnel";

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Root-readable file containing the remotely managed Cloudflare Tunnel token.
        Keep this file outside the Nix store and version control.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cloudflared-tunnel = {
      description = "Cloudflare Tunnel connector";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/tunnel-token";
        LoadCredential = "tunnel-token:${cfg.tokenFile}";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        Restart = "on-failure";
        RestartSec = "5s";
        Type = "notify";
      };
    };
  };
}
