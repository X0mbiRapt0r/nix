{ lib, pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # Preserve the kernel choice made during installation.
    loader = {
      efi.canTouchEfiVariables = true; # Allow NixOS to update UEFI boot entries.
      systemd-boot.enable = true; # Use systemd-boot on the NUC's EFI system partition.
    };
  };

  environment.systemPackages = with pkgs; [
    claude-code # Anthropic's headless CLI coding agent.
  ];

  # Apply the private work identity only below the dedicated work-repository root.
  home-manager.users.irish.programs.git.includes = [
    {
      condition = "gitdir/i:~/Documents/github.com/RudolphIrish/**";
      path = "~/Documents/github.com/X0mbiRapt0r/nix/hosts/QTM-Irish-NUC/.gitconfig-qtm.inc";
    }
  ];

  i18n.defaultLocale = "en_GB.UTF-8"; # System language and formatting locale.

  networking = {
    hostName = "QTM-Irish-NUC"; # Local network hostname and flake host name.
    networkmanager.enable = true; # Manage the NUC's Ethernet and any future Wi-Fi connection.
  };

  nix = {
    gc = {
      dates = "weekly"; # Run age-based garbage collection weekly via systemd.
      persistent = true; # Catch up after boot if the machine missed its scheduled run.
    };
    optimise.dates = [ "daily" ]; # Deduplicate the store daily via systemd.
  };

  nixpkgs.config.allowUnfreePredicate = package: lib.getName package == "claude-code";

  programs.zsh.enable = true; # Register zsh as the login shell managed by Home Manager.

  services.openssh.enable = true; # Keep the NUC remotely accessible during SSH hardening.

  system.stateVersion = "26.05"; # Fresh-install compatibility baseline; do not bump casually.

  time.timeZone = "Africa/Johannesburg"; # Office time zone.

  users.users.irish = {
    description = "Irish"; # Display name.
    extraGroups = [
      "networkmanager"
      "wheel"
    ]; # Network management and sudo access.
    isNormalUser = true; # Create the regular SSH and automation account.
    linger = true; # Start user services at boot without an insecure console auto-login.
    shell = pkgs.zsh; # Use the shared Home Manager-managed zsh configuration over SSH.
  };
}
