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
      pkgs.openssh
    ];
    text = ''
      identity="/var/lib/adlist/id_ed25519"
      output="/var/lib/adlist/combined-hosts.txt"
      router="10.12.12.1"
      router_user="hostlist-publisher"
      temporary_output="$(mktemp --tmpdir="$(dirname "$output")" .combined-hosts.XXXXXX)"
      trap 'rm -f "$temporary_output"' EXIT

      ${lib.getExe hostlistCompiler} \
        --config ${hostlistConfig} \
        --output "$temporary_output"

      # HostlistCompiler adds AdGuard-style metadata; RouterOS needs pure hosts entries.
      sed -i '/^!/d' "$temporary_output"
      test -s "$temporary_output"
      awk 'NF != 2 || $1 != "0.0.0.0" { exit 1 }' "$temporary_output"
      chmod 0640 "$temporary_output"
      mv -f "$temporary_output" "$output"
      trap - EXIT

      if [[ ! -f "$identity" ]]; then
        ssh-keygen -q -t ed25519 -N "" -C "hostlist-compiler@XR-NAS" -f "$identity"
        echo "Generated $identity; import $identity.pub for $router_user on the MikroTik, then run this service again."
        exit 0
      fi

      ssh_options=(
        -i "$identity"
        -o BatchMode=yes
        -o ConnectTimeout=10
        -o IdentitiesOnly=yes
        -o StrictHostKeyChecking=yes
        -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts
      )

      # Preserve the router's active list until the replacement has uploaded completely.
      scp -O -q "''${ssh_options[@]}" "$output" "$router_user@$router:combined-hosts.next.txt"
      ssh "''${ssh_options[@]}" "$router_user@$router" \
        ':local staged [/file/find where name="combined-hosts.next.txt"]; :if ([:len $staged] = 0) do={:error "staged adlist missing"}; :local current [/file/find where name="combined-hosts.txt"]; :if ([:len $current] > 0) do={/file/remove $current}; /file/set $staged name="combined-hosts.txt"; :if ([:len [/ip/dns/adlist/find where file="combined-hosts.txt"]] = 0) do={/ip/dns/adlist/add file="combined-hosts.txt"} else={/ip/dns/adlist/reload}; /ip/dns/adlist/print detail without-paging where file="combined-hosts.txt"'
    '';
  };
in
{
  imports = [
    ./services/icloud-mirror.nix
    ./services/streaming-addons.nix
  ];

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

  programs.ssh.knownHosts.xr-mt = {
    hostNames = [ "10.12.12.1" ];
    publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCm1ZppSLxzkUsVMLb+ypAgCMwJx7y1sSl0piCJteAuIei5geq24+9LGGdp7BDJ0Usf46WwmyzaqpXnAb36DYPASRn8lroEN0+sqTFGEll0Ox4nuJ0N6k2THql0yScJEKiobf/TMH2J+llLqt2DfSOxltyQ6YF7Tk8Sh8O12jHoD/aeC3h02TU6Srg4Knlbaom1P1RiwgepnetJvWQr/SEw5+w9+CLjEC9vqCgCRJ1dc7HTxXkTHHXsvWwTftUfdEjlGMyBVLRx+b7L7ShADKRYaGXu311qQau0Oem8ogHEAc4sI70/C/WkIzJS49i1UULoYvZWMEBzKeYM+5UTfhVH";
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

    btrfs.autoScrub.enable = true; # Check every declared Btrfs filesystem monthly for checksum errors.

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

    smartd.enable = true; # Monitor every detectable drive and report SMART health changes through the journal.
  };

  system.stateVersion = "26.05"; # Fresh-install compatibility baseline; do not bump casually.

  systemd = {
    services.hostlist-compiler = {
      after = [ "network-online.target" ];
      description = "Compile and publish the MikroTik DNS blocklist";
      environment.HOME = "/var/lib/adlist";
      serviceConfig = {
        ExecStart = lib.getExe buildHostlist;
        Group = "hostlist-compiler";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        StateDirectory = "adlist";
        StateDirectoryMode = "0750";
        Type = "oneshot";
        UMask = "0027";
        User = "hostlist-compiler";
        WorkingDirectory = "/var/lib/adlist";
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
      tokenFile = "/etc/xombiraptor/cloudflared-token";
    };

    ntfy = {
      baseUrl = "https://ntfy.xombiraptor.net";
      enable = true;
      environmentFile = "/etc/xombiraptor/ntfy.env";
    };
  };

  users = {
    groups.hostlist-compiler = { };

    users = {
      hostlist-compiler = {
        group = "hostlist-compiler";
        home = "/var/lib/adlist";
        isSystemUser = true;
      };

      irish = {
        extraGroups = [
          "hostlist-compiler" # Read the generated list without exposing the publisher's private key.
          "icloud" # Allow local read-only access to the live mirror and its snapshots.
        ];
        openssh.authorizedKeys.keys = [
          sshPublicKeys.irishMbp # Irish-MBP owns the private key; only its public half is deployed here.
        ];
      };
    };
  };
}
