{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Extra Hardware Support
  hardware.xone.enable = true; #environment.systemPackages = with pkgs; [ linuxKernel.packages.linux_6_6.xone ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.steam-hardware.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable Networking
  networking = {
    hostName = "xr-pc"; # Define your hostname.
    networkmanager.enable = true;
    enableIPv6 = false;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  };

  # Locale Settings
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_GB.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "steam";
  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "irish";
  };
  services.desktopManager.plasma6.enable = true;
  
  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.irish = {
    isNormalUser = true;
    description = "Irish";
    extraGroups = [ "networkmanager" "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  # Enable automatic login for the user.
  # services.getty.autologinUser = "irish";

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Install Steam
  programs = {
  gamemode.enable = true;
    gamescope = {
      enable = true;
      capSysNice = true;
      # args = [
      #   "--adaptive-sync"
      #   "--refresh 120"
      #   "-f"
      #   "--hdr-enabled"
      #   "--rt"
      # ];
    };
    steam = {
      enable = true;
      gamescopeSession = {
        enable = true;
        args = [
        #   "--adaptive-sync"
          "-r 120"
        #   "-f"
          "--hdr-enabled"
          "--rt"
        ];
        env = {
          # DSVK_ASYNC = "1";
          AMD_VULKAN_ICD = "RADV";
          DXVK_HDR = "1";
          DSVK_LOG_LEL = "none";
          VKD3D_DEBUG = "none";
          ENABLE_GAMESCOPE_WSI = "1";
          #MANGOHUD = "1";
          #MANGOHUD_CONFIG =
          #  "no_display"                       # start hidden; toggle with RCtrl+F12
          #  ",toggle_hud=RCtrl+F12"
          #  ",toggle_logging=RCtrl+F2"
          #  ",fps,frametime,frame_timing,cpu_stats,gpu_stats,temps"
          #  ",battery,ram,vram"
          #  ",time,arch"                       # show time + arch
          #  ",resolution,show_fps_limit"
          #  ",font_size=22,position=top-right";
        };
      };
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Tr>
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    btop
    cmatrix
    htop
    linuxKernel.packages.linux_6_12.xone
    neofetch
    mangohud
    lm_sensors
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by defaul>
  #   wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # OR
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configurati>
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system>
  system.stateVersion = "24.11"; # Did you read the comment?
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    channel = "https://nixos.org/channels/nixos-25.05";
  };

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "daily";
  };

}
