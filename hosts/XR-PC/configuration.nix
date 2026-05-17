{ config, pkgs, ... }:

let
  autoUpdateRepo = "/home/irish/Documents/github.com/X0mbiRapt0r/nix";

  # Steam's own pre-cache data lives inside Steam library folders, but Mesa/RADV
  # also keeps a driver shader cache under the user's cache directory by default.
  # Put that driver-side cache on the roomy game/data disk and make the limit
  # large enough that several Proton games do not constantly evict each other.
  steamShaderCacheDir = "/mnt/data1/steam-shader-cache";
  steamShaderCacheEnv = {
    MESA_SHADER_CACHE_DISABLE = "false"; # Keep Mesa's persistent on-disk cache enabled explicitly.
    MESA_SHADER_CACHE_DIR = steamShaderCacheDir; # Mesa will create/use `${steamShaderCacheDir}/mesa_shader_cache`.
    MESA_SHADER_CACHE_MAX_SIZE = "12G"; # Mesa defaults to 1G per architecture, which is tight for a gaming box.
  };
in
{
  boot = {
    loader = {
      systemd-boot.enable = true; # Use systemd-boot as the EFI bootloader.
      efi.canTouchEfiVariables = true; # Allow NixOS to update UEFI boot entries.
    };

    kernelPackages = pkgs.linuxPackages_latest; # Track the newest kernel series from pinned nixpkgs.
  };

  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi # AMD GPU monitoring CLI.
    usbutils # Provide `lsusb` for controller, adapter, and TV/CEC hardware diagnostics.
  ];

  hardware = {
    bluetooth = {
      enable = true; # Enable the Bluetooth service.
      settings = {
        General = {
          Experimental = true; # Show battery levels for supported Bluetooth devices.
          FastConnectable = true; # Let controllers reconnect faster at the cost of some power use.
        };
        Policy = {
          AutoEnable = true; # Power on Bluetooth adapters when they appear.
        };
      };
      powerOnBoot = true; # Bring Bluetooth up during boot.
    };
    graphics = {
      enable = true; # Enable Mesa/OpenGL/Vulkan graphics support.
      enable32Bit = true; # Include 32-bit graphics libraries for Steam/Proton.
    };
    steam-hardware.enable = true; # Add Steam controller/VR udev rules.
    xone.enable = true; # Enable Xbox Wireless Adapter support for Xbox One/Series controllers.
    xpadneo.enable = true; # Keep Xbox-over-Bluetooth support available for non-adapter controller use.
  };

  i18n.defaultLocale = "en_GB.UTF-8"; # System language/formatting locale.

  networking = {
    hostName = "XR-PC"; # Local network hostname.
    networkmanager.enable = true; # Manage networking through NetworkManager.
  };

  nix.gc = {
    automatic = true; # Enable scheduled garbage collection.
    dates = "daily"; # Run GC daily via systemd timer.
  };
  nix.optimise.dates = [ "daily" ]; # Deduplicate the store daily via systemd timer.

  nixpkgs.config.allowUnfree = true; # Allow unfree packages like Steam and Proton GE.
  nixpkgs.config.rocmSupport = true; # Build optional AMD ROCm support where packages expose it.

  programs = {
    gamemode.enable = true; # Let games request performance-oriented CPU/GPU tuning.
    gamescope = {
      enable = true; # Install Gamescope for the Steam session.
      capSysNice = true; # Allow Gamescope to raise scheduling priority.
    };
    steam = {
      enable = true; # Install and configure Steam.
      package = pkgs.steam.override {
        extraEnv = steamShaderCacheEnv; # Make every Steam launch inherit the persistent shader-cache settings.
      };
      gamescopeSession = {
        enable = true; # Add a dedicated Steam-in-Gamescope login session.
        args = [
          "-r 120" # Target 120 Hz in Gamescope.
          "--hdr-enabled" # Enable Gamescope HDR support.
          "--rt" # Ask Gamescope to use real-time scheduling.
        ];
        env = steamShaderCacheEnv // {
          DXVK_HDR = "1"; # Allow DXVK HDR when the game/Proton path supports it.
          DXVK_LOG_LEVEL = "none"; # Silence DXVK log files unless debugging.
          VKD3D_DEBUG = "none"; # Silence VKD3D-Proton debug output unless debugging.
          ENABLE_GAMESCOPE_WSI = "1"; # Use Gamescope's Vulkan WSI layer inside the session.
        };
      };
      extraCompatPackages = with pkgs; [
        proton-ge-bin # Add Proton GE as an available Steam compatibility tool.
      ];
      remotePlay.openFirewall = true; # Open firewall ports for Steam Remote Play.
      dedicatedServer.openFirewall = true; # Open firewall ports for Source dedicated servers.
      localNetworkGameTransfers.openFirewall = true; # Open firewall ports for LAN game transfers.
    };
    zsh.enable = true; # Register zsh as an available login shell.
  };

  services.blueman.enable = true; # Bluetooth tray/GUI manager for Plasma.
  services.displayManager.defaultSession = "steam"; # Auto-login lands in the Steam Gamescope session.
  services.desktopManager.plasma6.enable = true; # Install Plasma as the fallback full desktop.
  services.displayManager.sddm.enable = true; # Use SDDM as the graphical login manager.
  services.displayManager.sddm.wayland.enable = true; # Run the SDDM greeter on Wayland.
  services.displayManager = {
    autoLogin.enable = true; # Skip the login prompt on boot.
    autoLogin.user = "irish"; # User for the Steam-session auto-login.
  };
  services.openssh.enable = true; # Enable SSH for local remote access.
  services.pipewire = {
    enable = true; # Enable PipeWire audio.
    pulse.enable = true; # Provide PulseAudio compatibility for apps/games.
  };
  services.xrdp = {
    enable = true; # Enable RDP access.
    defaultWindowManager = "startplasma-x11"; # Start Plasma X11 for RDP sessions.
    openFirewall = true; # Open TCP 3389.
  };
  services.xserver.enable = true; # Keep X11 available for SDDM, Plasma X11, and xrdp.

  systemd.tmpfiles.rules = [
    "d ${steamShaderCacheDir} 0755 irish users - -" # Create the shared parent cache directory on boot/switch.
  ];

  systemd.services.xr-pc-auto-update = {
    description = "Update flake inputs, rebuild XR-PC, and run post-switch cleanup";
    after = [ "network-online.target" ]; # Wait for GitHub/cache access before pulling or updating inputs.
    wants = [ "network-online.target" ];
    restartIfChanged = false; # Do not launch a maintenance run just because this unit changed during a switch.
    path = [
      config.nix.package # Provides nix commands used by the helper scripts.
      config.system.build.nixos-rebuild # Provides nixos-rebuild for scripts/switch.
      pkgs.bash # Run the repo helper scripts explicitly.
      pkgs.coreutils # Basic utilities used by bash helpers.
      pkgs.git # Pull, commit, and push flake.lock updates.
      pkgs.openssh # Let Git remotes using SSH work from the systemd service.
      pkgs.util-linux # Provides runuser so repository mutation happens as irish, not root.
    ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = autoUpdateRepo;
    };
    script = ''
      # Keep Git-owned files owned by the normal user even though the service
      # itself runs as root for the rebuild step.
      runuser -u irish -- git -C ${autoUpdateRepo} pull --ff-only
      runuser -u irish -- bash ${autoUpdateRepo}/scripts/flake-update --repo ${autoUpdateRepo}

      # Reuse the same switch path as the `nrs` alias. The pull already
      # happened above, so avoid doing it twice.
      bash ${autoUpdateRepo}/scripts/switch XR-PC --repo ${autoUpdateRepo} --no-pull
    '';
  };

  systemd.timers.xr-pc-auto-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 02:00"; # Weekly couch-console maintenance window.
      Persistent = true; # If XR-PC was off, run once soon after it next boots.
      Unit = "xr-pc-auto-update.service";
    };
  };

  time.timeZone = "Africa/Johannesburg"; # System time zone.

  system.stateVersion = "24.11"; # NixOS compatibility version; do not bump casually.

  users.users.irish = {
    isNormalUser = true; # Create a regular login user.
    description = "Irish"; # Display name.
    extraGroups = [ "networkmanager" "render" "video" "wheel" ]; # Network, GPU, and sudo access.
    shell = pkgs.zsh; # Use the Home Manager-managed zsh config for SSH and local shells.
    packages = with pkgs; [
      tree # Directory tree viewer.
    ];
  };
}
