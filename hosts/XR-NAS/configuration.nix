{ pkgs, sshPublicKeys, ... }:

{
  boot = {
    # This HP firmware exposes malformed ACPI data to hp_bioscfg even after
    # applying HP's latest firmware package, preventing a normal boot. The NAS
    # does not need Linux access to HP BIOS settings, so keep the driver disabled.
    blacklistedKernelModules = [ "hp_bioscfg" ];
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
    firewall.interfaces.eno1.allowedTCPPorts = [ 445 ]; # Expose modern SMB only on the wired LAN interface.
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
          interfaces = "lo eno1";
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

  systemd.tmpfiles.rules = [
    "d /srv/data/share 2770 irish users -" # Keep the filesystem root private for snapshots and service-only data.
  ];

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
