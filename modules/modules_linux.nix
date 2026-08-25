{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    usbutils # Provide `lsusb` for Linux hardware diagnostics.
  ];

  i18n.defaultLocale = "en_GB.UTF-8"; # System language and formatting locale.

  networking.networkmanager.enable = true; # Use NetworkManager on every current Linux host.

  nix = {
    gc = {
      dates = "weekly"; # Run age-based garbage collection weekly via systemd.
      persistent = true; # Catch up after boot if the machine missed its scheduled run.
    };
    optimise.dates = [ "daily" ]; # Deduplicate the store daily via systemd.
  };

  services.openssh.enable = true; # Keep every Linux host available for local remote administration.

  time.timeZone = "Africa/Johannesburg"; # Shared system time zone.

  users.users.irish = {
    description = "Irish"; # Display name.
    extraGroups = [
      "networkmanager"
      "wheel"
    ]; # Network management and sudo access shared by every Linux host.
    isNormalUser = true; # Create the regular login and automation account.
    shell = pkgs.zsh; # Use the shared Home Manager-managed zsh configuration.
  };
}
