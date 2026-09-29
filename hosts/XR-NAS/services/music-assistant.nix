{ ... }:

let
  dataDirectory = "/var/lib/music-assistant";
in
{
  networking.firewall.interfaces.enp2s0.allowedTCPPorts = [
    8095 # Expose the authenticated Music Assistant UI and API on the LAN.
  ];

  virtualisation.oci-containers.containers.music-assistant = {
    environment.LOG_LEVEL = "info";
    extraOptions = [
      "--cap-drop=all"
      "--log-driver=journald"
      "--network=bridge"
      "--security-opt=no-new-privileges"
    ];
    image = "ghcr.io/music-assistant/server:2.10.4";
    ports = [ "10.12.12.11:8095:8095" ];
    volumes = [ "${dataDirectory}:/data" ];
  };

  systemd.tmpfiles.rules = [
    "d ${dataDirectory} 0700 root root -"
  ];
}
