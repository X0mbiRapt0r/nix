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

  displayManagerSessions = config.services.displayManager.sessionData.desktops;

  # The NixOS Steam module installs `steam-gamescope` into the system profile,
  # but that wrapper calls `gamescope` and `steam` by name. Graphical display
  # managers normally provide the profile PATH before launching sessions; greetd
  # starts initial sessions with a slimmer environment, so keep that small bit
  # of display-manager behavior here without bringing SDDM back.
  steamGamescopeSession = pkgs.writeShellScriptBin "xr-steam-gamescope-session" ''
    logFile=/tmp/xr-steam-gamescope-session.log
    export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH"

    {
      printf 'started=%s\n' "$(date --iso-8601=seconds)"
      id
      printf 'PATH=%s\n' "$PATH"
      printf 'XDG_RUNTIME_DIR=%s\n' "''${XDG_RUNTIME_DIR:-}"
      printf 'XDG_SESSION_ID=%s\n' "''${XDG_SESSION_ID:-}"
      command -v gamescope || true
      command -v steam || true
      ls -l /run/seatd.sock || true
      if [ -n "''${XDG_SESSION_ID:-}" ]; then
        loginctl show-session "$XDG_SESSION_ID" \
          -p Active \
          -p Class \
          -p Leader \
          -p Remote \
          -p Service \
          -p State \
          -p TTY \
          -p Type || true
      fi

      exec /run/current-system/sw/bin/steam-gamescope
    } >"$logFile" 2>&1
  '';
  steamGamescopeCommand = "${steamGamescopeSession}/bin/xr-steam-gamescope-session";
  tuigreetCommand = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --user-menu --sessions ${displayManagerSessions}/share/wayland-sessions --xsessions ${displayManagerSessions}/share/xsessions --cmd ${steamGamescopeCommand}";
in
{
  boot = {
    consoleLogLevel = 0; # Keep kernel messages off the TV unless the boot is badly broken.
    initrd.verbose = false; # Suppress NixOS initrd status chatter on the console.
    kernelPackages = pkgs.linuxPackages_latest; # Track the newest kernel series from pinned nixpkgs.
    kernelParams = [
      "quiet" # Ask the kernel to keep normal boot output quiet.
      "udev.log_level=3" # Show only udev errors during boot, not routine device discovery.
      "usbcore.quirks=045e:02e6:k" # Disable USB link power management for the Xbox Wireless Adapter; it times out during radio init.
      "video=HDMI-A-1:e" # Keep the TV HDMI connector advertised so Steam/Gamescope autologin does not race a sleeping display.
    ];

    loader = {
      efi.canTouchEfiVariables = true; # Allow NixOS to update UEFI boot entries.
      systemd-boot.enable = true; # Use systemd-boot as the EFI bootloader.
      timeout = 0; # Skip the visible boot menu during normal couch-console startup.
    };
  };

  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi # AMD GPU monitoring CLI.
    usbutils # Provide `lsusb` for controller, adapter, and TV/CEC hardware diagnostics.
  ];

  hardware = {
    bluetooth = {
      enable = true; # Enable the Bluetooth service.
      powerOnBoot = true; # Bring Bluetooth up during boot.
      settings = {
        General = {
          Experimental = true; # Show battery levels for supported Bluetooth devices.
          FastConnectable = true; # Let controllers reconnect faster at the cost of some power use.
        };
        Policy = {
          AutoEnable = true; # Power on Bluetooth adapters when they appear.
        };
      };
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

  nix = {
    gc = {
      automatic = true; # Enable scheduled garbage collection.
      dates = "daily"; # Run GC daily via systemd timer.
    };
    optimise.dates = [ "daily" ]; # Deduplicate the store daily via systemd timer.
  };

  nixpkgs.config = {
    allowUnfree = true; # Allow unfree packages like Steam and Proton GE.
    rocmSupport = true; # Build optional AMD ROCm support where packages expose it.
  };

  programs = {
    gamemode.enable = true; # Let games request performance-oriented CPU/GPU tuning.
    gamescope = {
      capSysNice = false; # Keep Steam on normal user-namespace bubblewrap; the setuid wrapper currently aborts before Steam starts.
      enable = true; # Install Gamescope for the Steam session.
    };
    steam = {
      dedicatedServer.openFirewall = true; # Open firewall ports for Source dedicated servers.
      enable = true; # Install and configure Steam.
      extraCompatPackages = with pkgs; [
        proton-ge-bin # Add Proton GE as an available Steam compatibility tool.
      ];
      gamescopeSession = {
        args = [
          "--allow-deferred-backend" # Give logind/DRM a chance to settle when greetd starts Steam very early in boot.
          "--backend"
          "drm" # Force the standalone TTY/KMS backend instead of a nested or headless fallback.
          "--hdr-enabled" # Enable Gamescope HDR support.
          "-r"
          "120" # Target 120 Hz in Gamescope.
        ];
        enable = true; # Add a dedicated Steam-in-Gamescope login session.
        env = steamShaderCacheEnv // {
          DXVK_HDR = "1"; # Allow DXVK HDR when the game/Proton path supports it.
          DXVK_LOG_LEVEL = "none"; # Silence DXVK log files unless debugging.
          ENABLE_GAMESCOPE_WSI = "1"; # Use Gamescope's Vulkan WSI layer inside the session.
          VKD3D_DEBUG = "none"; # Silence VKD3D-Proton debug output unless debugging.
        };
      };
      localNetworkGameTransfers.openFirewall = true; # Open firewall ports for LAN game transfers.
      package = pkgs.steam.override {
        extraEnv = steamShaderCacheEnv; # Make every Steam launch inherit the persistent shader-cache settings.
      };
      remotePlay.openFirewall = true; # Open firewall ports for Steam Remote Play.
    };
    zsh.enable = true; # Register zsh as an available login shell.
  };

  services = {
    blueman.enable = true; # Bluetooth tray/GUI manager for Plasma.
    desktopManager.plasma6.enable = true; # Install Plasma as the fallback full desktop.
    displayManager.sddm.enable = false; # Use greetd for the Steam console path instead of SDDM's experimental Wayland greeter.
    greetd = {
      enable = true; # Run the minimal login manager for local console sessions.
      settings = {
        default_session = {
          command = tuigreetCommand; # Text fallback if Steam exits or autologin is unavailable.
          user = "greeter"; # Unprivileged greeter account created by the greetd module.
        };
        initial_session = {
          command = steamGamescopeCommand; # Boot straight into the generated Steam Gamescope session.
          user = "irish"; # Match the previous SDDM autologin user.
        };
      };
      useTextGreeter = true; # Tell systemd to keep tty1 clean for tuigreet fallback prompts.
    };
    openssh.enable = true; # Enable SSH for local remote access.
    pipewire = {
      enable = true; # Enable PipeWire audio.
      pulse.enable = true; # Provide PulseAudio compatibility for apps/games.
    };
    seatd.enable = true; # Give TTY-launched Wayland compositors a dedicated seat-management socket.
    udev.extraRules = ''
      # Keep the Xbox Wireless Adapter awake and wake-capable. It enumerates at
      # boot, but xone currently times out initializing the radio unless the USB
      # side is kept boring and fully powered.
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02e6", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02e6", TEST=="power/control", ATTR{power/control}="on"
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02e6", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
    '';
    xrdp = {
      defaultWindowManager = "startplasma-x11"; # Start Plasma X11 for RDP sessions.
      enable = true; # Enable RDP access.
      openFirewall = true; # Open TCP 3389.
    };
    xserver.enable = true; # Keep X11 available for SDDM, Plasma X11, and xrdp.
  };

  systemd = {
    services.greetd = {
      after = [ "seatd.service" ]; # Start Steam/Gamescope only after seatd can grant KMS/input access.
      wants = [ "seatd.service" ]; # Pull seatd in with greetd even if target ordering changes later.
    };

    services.xr-pc-auto-update = {
      after = [ "network-online.target" ]; # Wait for GitHub/cache access before pulling or updating inputs.
      description = "Update flake inputs, rebuild XR-PC, and run post-switch cleanup";
      path = [
        config.nix.package # Provides nix commands used by the helper scripts.
        config.system.build.nixos-rebuild # Provides nixos-rebuild for scripts/switch.
        pkgs.bash # Run the repo helper scripts explicitly.
        pkgs.coreutils # Basic utilities used by bash helpers.
        pkgs.git # Pull, commit, and push flake.lock updates.
        pkgs.openssh # Let Git remotes using SSH work from the systemd service.
        pkgs.util-linux # Provides runuser so repository mutation happens as irish, not root.
      ];
      restartIfChanged = false; # Do not launch a maintenance run just because this unit changed during a switch.
      script = ''
        # Keep Git-owned files owned by the normal user even though the service
        # itself runs as root for the rebuild step.
        runuser -u irish -- git -C ${autoUpdateRepo} pull --ff-only
        runuser -u irish -- bash ${autoUpdateRepo}/scripts/flake-update --repo ${autoUpdateRepo}

        # Reuse the same switch path as the `nrs` alias. The pull already
        # happened above, so avoid doing it twice.
        bash ${autoUpdateRepo}/scripts/switch XR-PC --repo ${autoUpdateRepo} --no-pull
      '';
      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = autoUpdateRepo;
      };
      wants = [ "network-online.target" ];
    };

    timers.xr-pc-auto-update = {
      timerConfig = {
        OnCalendar = "Sun 02:00"; # Weekly couch-console maintenance window.
        Persistent = true; # If XR-PC was off, run once soon after it next boots.
        Unit = "xr-pc-auto-update.service";
      };
      wantedBy = [ "timers.target" ];
    };

    tmpfiles.rules = [
      "d ${steamShaderCacheDir} 0755 irish users - -" # Create the shared parent cache directory on boot/switch.
    ];
  };

  time.timeZone = "Africa/Johannesburg"; # System time zone.

  system.stateVersion = "24.11"; # NixOS compatibility version; do not bump casually.

  users.users.irish = {
    description = "Irish"; # Display name.
    extraGroups = [
      "networkmanager"
      "render"
      "seat"
      "video"
      "wheel"
    ]; # Network, GPU, and sudo access.
    isNormalUser = true; # Create a regular login user.
    packages = with pkgs; [
      tree # Directory tree viewer.
    ];
    shell = pkgs.zsh; # Use the Home Manager-managed zsh config for SSH and local shells.
  };
}
