{
  lib,
  pkgs,
  sshPublicKeys,
  ...
}:

let
  hostlistCompiler = pkgs.callPackage ../../packages/adguard-hostlist-compiler.nix { };
  # Keep hosts syntax throughout: RouterOS cannot consume HostlistCompiler's
  # usual compressed AdGuard-rule output.
  hostlistConfig = ./hostlist-compiler.json;

  buildHostlist = pkgs.writeShellApplication {
    name = "build-hostlist";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnused
    ];
    text = ''
      output="/var/lib/hostlist-compiler/combined-hosts.txt"
      temporary_output="$(mktemp --tmpdir="$(dirname "$output")" .combined-hosts.XXXXXX)"
      trap 'rm -f "$temporary_output"' EXIT

      ${lib.getExe hostlistCompiler} \
        --config ${hostlistConfig} \
        --output "$temporary_output"

      # HostlistCompiler adds AdGuard-style metadata; RouterOS needs pure hosts entries.
      sed -i '/^!/d' "$temporary_output"
      test -s "$temporary_output"
      awk 'NF != 2 || $1 != "0.0.0.0" { exit 1 }' "$temporary_output"
      chmod 0644 "$temporary_output"
      mv -f "$temporary_output" "$output"
      trap - EXIT
    '';
  };
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # Preserve the kernel choice made during installation.
    kernelParams = [ "consoleblank=300" ]; # Blank the emergency console after five idle minutes.
    loader = {
      efi.canTouchEfiVariables = true; # Allow NixOS to update UEFI boot entries.
      systemd-boot.enable = true; # Use systemd-boot on the NAS's EFI system partition.
    };
  };

  fileSystems."/srv/data" = {
    device = "/dev/disk/by-uuid/5dfc7ee0-b798-4bc3-9f54-715dc1ccdb69";
    fsType = "btrfs";
    # Keep remote administration available if the data SSD fails. Automounting
    # also prevents services from silently writing into the NVMe mountpoint.
    options = [
      "compress=zstd"
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
    ];
  };

  networking = {
    firewall.interfaces.enp2s0.allowedTCPPorts = [ 445 ]; # Expose modern SMB only on the wired LAN interface.
    hostName = "XR-NAS"; # Local network hostname and flake host name.
  };

  services = {
    avahi.extraServiceFiles.smb = ''
      <?xml version="1.0" standalone='no'?>
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
      </service-group>
    '';

    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };

    samba = {
      enable = true;
      nmbd.enable = false; # Modern clients use direct SMB and mDNS instead of legacy NetBIOS discovery.
      settings = {
        global = {
          "bind interfaces only" = "yes";
          "disable netbios" = "yes";
          "fruit:aapl" = "yes";
          interfaces = "lo enp2s0";
          "load printers" = "no";
          "map to guest" = "never";
          "printcap name" = "/dev/null";
          security = "user";
          "server role" = "standalone server";
          "server string" = "XR-NAS";
          "smb ports" = "445";
        };

        Data = {
          browseable = "yes";
          comment = "XR-NAS shared data";
          "force group" = "users";
          "fruit:encoding" = "native";
          "fruit:metadata" = "netatalk";
          "fruit:resource" = "file";
          "guest ok" = "no";
          "inherit permissions" = "yes";
          path = "/srv/data/share";
          "read only" = "no";
          "valid users" = "irish";
          "vfs objects" = "catia fruit streams_xattr";
        };
      };
      winbindd.enable = false; # Local user authentication does not need domain identity services.
    };
  };

  system.stateVersion = "26.05"; # Fresh-install compatibility baseline; do not bump casually.

  systemd = {
    services.hostlist-compiler = {
      after = [ "network-online.target" ];
      description = "Compile the local DNS blocklist";
      serviceConfig = {
        DynamicUser = true;
        ExecStart = lib.getExe buildHostlist;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        StateDirectory = "hostlist-compiler";
        Type = "oneshot";
        UMask = "0022";
        WorkingDirectory = "/var/lib/hostlist-compiler";
      };
      wants = [ "network-online.target" ];
    };

    timers.hostlist-compiler = {
      description = "Refresh the local DNS blocklist daily";
      timerConfig = {
        OnBootSec = "15m";
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
        Unit = "hostlist-compiler.service";
      };
      wantedBy = [ "timers.target" ];
    };

    tmpfiles.rules = [
      "d /srv/data/share 2770 irish users -" # Keep the filesystem root private for snapshots and service-only data.
    ];
  };

  xombiraptor.services = {
    cloudflareTunnel = {
      enable = true;
      tokenFile = "/home/irish/Documents/Code/nix/.private/services/XR-NAS/cloudflared-token";
    };

    ntfy = {
      baseUrl = "https://ntfy.xombiraptor.net";
      enable = true;
      environmentFile = "/home/irish/Documents/Code/nix/.private/services/XR-NAS/ntfy.env";
    };
  };

  users.users.irish.openssh.authorizedKeys.keys = [
    sshPublicKeys.irishMbp # Irish-MBP owns the private key; only its public half is deployed here.
  ];
}
