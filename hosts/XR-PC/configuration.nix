{ lib, pkgs, ... }:

let
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

  # Desktop GPUs usually do not expose HDMI-CEC to Linux directly. Leave the
  # automation disabled until XR-PC has real CEC hardware, for example a
  # Pulse-Eight USB-CEC adapter sitting inline on the HDMI cable.
  enableHdmiCecAutomation = false;
  cecClient = "${pkgs.libcec}/bin/cec-client";
in
{
  boot = {
    loader = {
      systemd-boot.enable = true; # Use systemd-boot as the EFI bootloader.
      efi.canTouchEfiVariables = true; # Allow NixOS to update UEFI boot entries.
    };

    extraModprobeConfig = ''
      # Keep the USB Bluetooth controller awake. Xbox controllers over Bluetooth
      # are much less forgiving than the official Xbox wireless adapter when the
      # host Bluetooth chip runtime-suspends during idle moments.
      options btusb enable_autosuspend=0
    '';

    kernelPackages = pkgs.linuxPackages_latest; # Track the newest kernel series from pinned nixpkgs.
  };

  environment.systemPackages = with pkgs; [
    libcec # Provides `cec-client` for HDMI-CEC testing/automation once CEC hardware is present.
    rocmPackages.rocm-smi # AMD GPU monitoring CLI.
    usbutils # Provides `lsusb`, useful for finding the Bluetooth adapter and its wake settings.
  ];

  hardware = {
    bluetooth = {
      enable = true; # Enable the Bluetooth service.
      input = {
        General = {
          IdleTimeout = 0; # Never disconnect Bluetooth HID devices merely because they were idle.
        };
      };
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
    xpadneo.enable = true; # Better Xbox controller support over Bluetooth.
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
  services.udev.extraRules = ''
    # When a USB Bluetooth adapter is added/rebound, reapply the power policy
    # below. The service is harmless if no btusb device exists.
    ACTION=="add|change", SUBSYSTEM=="usb", DRIVERS=="btusb", TAG+="systemd", ENV{SYSTEMD_WANTS}+="bluetooth-usb-power.service"
  '';
  services.xrdp = {
    enable = true; # Enable RDP access.
    defaultWindowManager = "startplasma-x11"; # Start Plasma X11 for RDP sessions.
    openFirewall = true; # Open TCP 3389.
  };
  services.xserver.enable = true; # Keep X11 available for SDDM, Plasma X11, and xrdp.

  systemd.services = {
    bluetooth-usb-power = {
      description = "Keep USB Bluetooth adapters awake for controller reliability";
      after = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.coreutils ];
      serviceConfig.Type = "oneshot";
      script = ''
        # btusb binds to USB interface paths like `1-9:1.0`; the parent
        # directory is the actual USB device that owns the power controls.
        for interface in /sys/bus/usb/drivers/btusb/*:*; do
          [ -e "$interface" ] || continue
          device="$(readlink -f "$interface/..")"

          # `on` disables runtime autosuspend for this adapter instance.
          if [ -w "$device/power/control" ]; then
            echo on > "$device/power/control"
          fi

          # `enabled` lets a suspended PC wake when the adapter receives a
          # supported remote wake event, assuming the firmware/BIOS allows it.
          if [ -w "$device/power/wakeup" ]; then
            echo enabled > "$device/power/wakeup"
          fi
        done
      '';
    };
  } // lib.optionalAttrs enableHdmiCecAutomation {
    hdmi-cec-tv-on = {
      description = "Wake the TV and select XR-PC as the active HDMI source";
      after = [ "display-manager.service" ];
      wantedBy = [ "graphical.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        # Logical address 0 is the TV. `as` announces this HDMI device as the
        # active source, which is the CEC equivalent of a console taking input.
        echo "on 0" | ${cecClient} -s -d 1 || true
        echo "as" | ${cecClient} -s -d 1 || true
      '';
    };

    hdmi-cec-tv-standby = {
      description = "Put the TV in standby before XR-PC sleeps or powers off";
      before = [ "sleep.target" "poweroff.target" ];
      wantedBy = [ "sleep.target" "poweroff.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        # Send standby before the machine goes away; a fully powered-off PC
        # cannot send new CEC commands after shutdown completes.
        echo "standby 0" | ${cecClient} -s -d 1 || true
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d ${steamShaderCacheDir} 0755 irish users - -" # Create the shared parent cache directory on boot/switch.
  ];

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
