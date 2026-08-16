{ config, pkgs, ... }:

{
  boot = {
    # The BCM4360's 802.11ac PHY is unsupported by b43; use Broadcom's wl driver.
    blacklistedKernelModules = [
      "b43"
      "bcma"
    ];
    # Stay on NixOS's default kernel because broadcom-sta does not build against the latest series.
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    kernelModules = [ "wl" ];

    loader = {
      efi.canTouchEfiVariables = true; # Allow NixOS to update UEFI boot entries.
      systemd-boot.enable = true; # Use systemd-boot as the EFI bootloader.
    };
  };
  boot.loader.systemd-boot.memtest86.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl # Control the display and Apple SMC keyboard backlights from the CLI.
    usbutils # Provide `lsusb` for hardware diagnostics.
  ];

  hardware = {
    bluetooth = {
      enable = true; # Enable Bluetooth for controllers and peripherals.
      powerOnBoot = true; # Bring the adapter up during boot.
      settings = {
        General = {
          Experimental = true; # Show battery levels for supported Bluetooth devices.
          FastConnectable = true; # Let controllers reconnect faster at a small power cost.
        };
        Policy.AutoEnable = true; # Power on Bluetooth adapters when they appear.
      };
    };
    enableRedistributableFirmware = true; # Supply firmware and enable Intel CPU microcode updates.
  };

  i18n.defaultLocale = "en_GB.UTF-8"; # System language/formatting locale.

  networking = {
    hostName = "Irish-MBP-2013"; # Local network hostname.
    networkmanager.enable = true; # Manage Ethernet and Wi-Fi through NetworkManager.
  };

  nix = {
    gc = {
      dates = "weekly"; # Run age-based GC weekly via systemd.
      persistent = true; # Catch up after boot if the machine missed its scheduled run.
    };
    optimise.dates = [ "daily" ]; # Deduplicate the store daily via systemd timer.
  };

  nixpkgs.config = {
    # Limit the insecure exception to the unmaintained driver required by the BCM4360.
    allowInsecurePredicate = package: package.pname == "broadcom-sta";
    allowUnfree = true; # Allow Broadcom's driver, Steam, and Proton GE.
  };

  programs = {
    gamemode.enable = true; # Let games request performance-oriented CPU/GPU tuning.
    steam = {
      enable = true; # Install Steam and its required 32-bit graphics support.
      extraCompatPackages = with pkgs; [
        proton-ge-bin # Add Proton GE as an available Steam compatibility tool.
      ];
      localNetworkGameTransfers.openFirewall = true; # Open ports for LAN game transfers.
      remotePlay.openFirewall = true; # Open ports for Steam Remote Play.
    };
    zsh.enable = true; # Register zsh as an available login shell.
  };

  services = {
    displayManager.autoLogin = {
      enable = true; # Start Xfce directly for this single-user test laptop.
      user = "irish";
    };
    mbpfan.enable = true; # Keep Apple-specific fan control active under sustained gaming loads.
    openssh.enable = true; # Enable SSH for local remote access.
    pipewire = {
      enable = true; # Enable PipeWire audio.
      pulse.enable = true; # Provide PulseAudio compatibility for apps and games.
    };
    xserver = {
      desktopManager.xfce.enable = true; # Use the mature, lightweight X11 desktop on this legacy NVIDIA GPU.
      displayManager.lightdm.enable = true; # Provide a conventional fallback greeter when auto-login is bypassed.
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  system.stateVersion = "26.05"; # Fresh-install compatibility baseline; do not bump casually.

  time.timeZone = "Africa/Johannesburg"; # System time zone.

  users.users.irish = {
    description = "Irish"; # Display name.
    extraGroups = [
      "networkmanager"
      "render"
      "video"
      "wheel"
    ]; # Network, GPU, and sudo access.
    isNormalUser = true; # Create a regular login user.
    shell = pkgs.zsh; # Use the Home Manager-managed zsh config for SSH and local shells.
  };
}
