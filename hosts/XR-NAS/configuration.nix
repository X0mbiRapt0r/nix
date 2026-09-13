{ pkgs, sshPublicKeys, ... }:

{
  boot = {
    # This HP firmware exposes malformed ACPI data to hp_bioscfg even after
    # applying HP's latest firmware package, preventing a normal boot. The NAS
    # does not need Linux access to HP BIOS settings, so keep the driver disabled.
    blacklistedKernelModules = [ "hp_bioscfg" ];
    kernelPackages = pkgs.linuxPackages_latest; # Preserve the kernel choice made during installation.
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

  networking.hostName = "XR-NAS"; # Local network hostname and flake host name.

  system.stateVersion = "26.05"; # Fresh-install compatibility baseline; do not bump casually.

  users.users.irish.openssh.authorizedKeys.keys = [
    sshPublicKeys.irishMbp # Irish-MBP owns the private key; only its public half is deployed here.
  ];
}
