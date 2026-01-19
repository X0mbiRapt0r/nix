{ config, lib, pkgs, ... }:

{ 
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  environment.systemPackages = with pkgs; [ # List packages installed in system profile.
    (btop.override { rocmSupport = true; }) # btop with AMD GPU support
    rocmPackages.rocm-smi # provides rocm-smi
    firefox
    # mangohud
    # lm_sensors
    # wineWowPackages.waylandFull
    # winetricks
  ];

  hardware = {
    bluetooth = {
      enable = true;
      settings = {
        General = {
          Experimental = true; # Shows battery charge of connected devices on supported Bluetooth adapters. Defaults to 'false'.
          FastConnectable = true; # When enabled other devices can connect faster to us, however the tradeoff is increased power consumption. Defaults to 'false'.
        };
        Policy = {
          AutoEnable = true; # Enable all controllers when they are found. This includes adapters present on start as well as adapters that are plugged in later on. Defaults to 'true'.
        };
      };
      powerOnBoot = true;
    };
    graphics = {
      # amd = {
      #   dpm = true; # Dynamic Power Management
      #   enable = true;
      # }; 
      enable = true;
      enable32Bit = true;
    };
    steam-hardware.enable = true;
    xpadneo.enable = true; # Xbox Series controller over Bluetooth (recommended)
  };

  i18n.defaultLocale = "en_GB.UTF-8";

  networking = {
    hostName = "XR-PC"; # Define your hostname.
    networkmanager.enable = true;
    # enableIPv6 = false;
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
  };
  nix.optimise.dates = [ "daily" ];  # systemd.time(7) format
  # nix.settings.auto-optimise-store = true;
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true; # Allow unfree packages
  nixpkgs.config.rocmSupport = true; # Ensure packages that have optional ROCm support can enable it

  programs = { # Install Steam
    gamemode.enable = true;
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    # gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };
    # mtr.enable = true;
    steam = {
      enable = true;
      gamescopeSession = {
        enable = true;
        args = [
          "-r 120"
          "--hdr-enabled"
          "--rt"
        ];
        env = {
          # DSVK_ASYNC = "1";
          AMD_VULKAN_ICD = "RADV";
          DXVK_HDR = "1";
          DSVK_LOG_LEVEL = "none";
          VKD3D_DEBUG = "none";
          ENABLE_GAMESCOPE_WSI = "1";
        };
      };
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
  };

  services.blueman.enable = true; # Optional but handy: tray/GUI Bluetooth manager for Plasma
  services.displayManager.defaultSession = "steam";
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "irish";
  };
  # services.getty.autologinUser = "irish"; # Enable automatic login for the user.
  services.openssh.enable = true; # Enable the OpenSSH daemon.
  services.pipewire = { # Enable sound.
    enable = true;
    pulse.enable = true;
  };
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11";
    openFirewall = true; # opens TCP 3389
  };
  services.xserver.enable = true; # Enable the X11 windowing system.
  # services.xserver.displayManager.steam.enable = true; # Enable SteamOS display manager
  # services.xserver.xkb.layout = "us"; # Configure keymap in X11
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  time.timeZone = "Africa/Johannesburg";  # Locale Settings
  
  system.stateVersion = "24.11";

  users.users.irish = {
    isNormalUser = true;
    description = "Irish";
    extraGroups = [ "networkmanager" "render" "video" "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };
}