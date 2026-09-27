{ config, lib, ... }:

let
  aiostreamsEnvironmentFile = "/etc/xombiraptor/aiostreams.env";
  cometEnvironmentFile = "/etc/xombiraptor/comet.env";
  networkName = "streaming-addons";
  podman = lib.getExe config.virtualisation.podman.package;
in
{
  virtualisation = {
    oci-containers = {
      backend = "podman";
      containers = {
        aiostreams = {
          environment = {
            AIOSTREAMS_AUTH_REQUIRED = "true";
            BASE_URL = "https://streams.xombiraptor.net";
            LOG_FORMAT = "json";
            LOG_LEVEL = "info";
          };
          environmentFiles = [ aiostreamsEnvironmentFile ];
          extraOptions = [
            "--cap-drop=all"
            "--log-driver=journald"
            "--network=${networkName}"
            "--security-opt=no-new-privileges"
          ];
          image = "ghcr.io/viren070/aiostreams:v2.34.1";
          ports = [ "127.0.0.1:3000:3000" ];
          volumes = [ "/var/lib/aiostreams:/app/data" ];
        };

        comet = {
          dependsOn = [ "comet-postgres" ];
          environment = {
            DATABASE_TYPE = "postgresql";
            FASTAPI_PORT = "8000";
            POSTGRES_DB = "comet";
            POSTGRES_USER = "comet";
            PUBLIC_BASE_URL = "https://comet.xombiraptor.net";
          };
          environmentFiles = [ cometEnvironmentFile ];
          extraOptions = [
            "--cap-drop=all"
            "--log-driver=journald"
            "--network=${networkName}"
            "--network-alias=comet"
            "--read-only"
            "--security-opt=no-new-privileges"
            "--tmpfs=/tmp:size=64m,mode=1777"
          ];
          # Upstream publishes moving channel tags only; pin the official multi-architecture manifest.
          image = "ghcr.io/g0ldyy/comet@sha256:dca62133336e02784d02aaad861381820674d1c8e3e98a03797610b81ee4defe";
          ports = [ "127.0.0.1:8000:8000" ];
          volumes = [ "/var/lib/comet:/app/data" ];
        };

        comet-postgres = {
          environment = {
            POSTGRES_DB = "comet";
            POSTGRES_USER = "comet";
          };
          environmentFiles = [ cometEnvironmentFile ];
          extraOptions = [
            "--log-driver=journald"
            "--network=${networkName}"
            "--network-alias=comet-postgres"
          ];
          image = "docker.io/library/postgres:18-alpine";
          volumes = [ "comet-postgres:/var/lib/postgresql" ];
        };
      };
    };

    podman.enable = true;
  };

  systemd = {
    services = {
      podman-aiostreams = {
        after = [ "streaming-addons-network.service" ];
        requires = [ "streaming-addons-network.service" ];
      };

      podman-comet = {
        after = [ "streaming-addons-network.service" ];
        requires = [ "streaming-addons-network.service" ];
      };

      podman-comet-postgres = {
        after = [ "streaming-addons-network.service" ];
        requires = [ "streaming-addons-network.service" ];
      };

      streaming-addons-network = {
        description = "Create the private AIOStreams and Comet container network";
        before = [
          "podman-aiostreams.service"
          "podman-comet-postgres.service"
          "podman-comet.service"
        ];
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
        script = ''
          ${podman} network exists ${networkName} || ${podman} network create ${networkName}
        '';
        wantedBy = [ "multi-user.target" ];
      };
    };

    tmpfiles.rules = [
      "d /var/lib/aiostreams 0700 root root -"
      "d /var/lib/comet 0700 root root -"
      "d /var/log/journal 2755 root systemd-journal -"
    ];
  };
}
