{
  config,
  lib,
  pkgs,
  ...
}:

let
  sessionStateFile = "$XDG_RUNTIME_DIR/xr-session-next";
  waylandSessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";

  # The NixOS Steam module installs `steam-gamescope` into the system profile,
  # but that wrapper calls `gamescope` and `steam` by name. Graphical display
  # managers normally provide the profile PATH before launching sessions; greetd
  # starts initial sessions with a slimmer environment, so keep that small bit
  # of display-manager behavior here without bringing SDDM back.
  steamGamescopeSession = pkgs.writeShellScriptBin "xr-steam-gamescope-session" ''
    export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH"
    exec /run/current-system/sw/bin/steam-gamescope
  '';
  steamGamescopeCommand = "${steamGamescopeSession}/bin/xr-steam-gamescope-session";

  # Steam calls this SteamOS-compatible command for "Switch to Desktop". The
  # same command backs Plasma's return shortcut, keeping the public interface
  # familiar while the router below owns the actual compositor lifecycle.
  steamSessionSelect = pkgs.writeShellApplication {
    name = "steamos-session-select";
    text = ''
      state_file="${sessionStateFile}"
      target="''${1:-plasma}"

      case "$target" in
        desktop|plasma|plasma-wayland|plasma-wayland-persistent)
          printf 'plasma\n' > "$state_file"
          steam -shutdown
          ;;
        game|gamescope|gaming)
          printf 'gamescope\n' > "$state_file"
          ${lib.getExe' pkgs.kdePackages.qttools "qdbus"} \
            org.kde.ksmserver \
            /KSMServer \
            org.kde.KSMServerInterface.closeSession
          ;;
        *)
          printf 'Usage: steamos-session-select {plasma|gamescope}\n' >&2
          exit 2
          ;;
      esac
    '';
  };

  # Keep greetd's authenticated session alive while Gamescope and Plasma take
  # turns as its foreground child. This avoids nested desktops, privileged
  # display-manager restarts, and a login prompt between modes.
  steamSessionRouter = pkgs.writeShellApplication {
    name = "xr-session-router";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      state_file="${sessionStateFile}"
      next_session="gamescope"

      export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH"

      while true; do
        rm -f "$state_file"

        case "$next_session" in
          plasma)
            env \
              XDG_CURRENT_DESKTOP=KDE \
              XDG_SESSION_DESKTOP=KDE \
              XDG_SESSION_TYPE=wayland \
              ${lib.getExe' pkgs.dbus "dbus-run-session"} -- \
              ${lib.getExe' pkgs.kdePackages.plasma-workspace "startplasma-wayland"} || true
            ;;
          *)
            ${steamGamescopeCommand} || true
            ;;
        esac

        next_session="gamescope"
        if [[ -r "$state_file" ]]; then
          requested_session=""
          IFS= read -r requested_session < "$state_file" || true
          case "$requested_session" in
            gamescope|plasma)
              next_session="$requested_session"
              ;;
          esac
        else
          # Avoid a tight restart loop if a compositor fails before it can run.
          sleep 1
        fi
      done
    '';
  };
  steamSessionRouterCommand = lib.getExe steamSessionRouter;
  steamSessionSelectCommand = lib.getExe steamSessionSelect;
  tuigreetCommand = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --user-menu --sessions ${waylandSessions} --cmd ${steamSessionRouterCommand}";
in
{
  boot = {
    consoleLogLevel = 0; # Suppress kernel console chatter; diagnostics remain available in the journal.
    initrd = {
      kernelModules = [
        "amdgpu" # Bring the RX 6800 XT up before greetd starts, avoiding the early Gamescope/RADV race.
      ];
      verbose = false; # Suppress NixOS initrd status chatter on the console.
    };
    kernelPackages = pkgs.linuxPackages_latest; # Track the newest kernel series available in the current nixpkgs lock.
    kernelParams = [
      "quiet" # Ask the kernel to keep normal boot output quiet.
      "udev.log_level=3" # Show only udev errors during boot, not routine device discovery.
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
    xone.enable = true; # Enable Xbox Wireless Adapter support for Xbox One/Series controllers.
    xpadneo.enable = true; # Keep Xbox-over-Bluetooth support available for non-adapter controller use.
  };

  home-manager.users.irish.home.file."Desktop/Return to Gaming Mode.desktop" = {
    executable = true;
    text = ''
      [Desktop Entry]
      Categories=Game;System;
      Comment=Leave Plasma and return to the Steam Gamescope session
      Exec=${steamSessionSelectCommand} gamescope
      Icon=steam
      Name=Return to Gaming Mode
      StartupNotify=false
      Terminal=false
      Type=Application
    '';
  };

  i18n.defaultLocale = "en_GB.UTF-8"; # System language/formatting locale.

  networking = {
    hostName = "XR-PC"; # Local network hostname.
    networkmanager.enable = true; # Manage networking through NetworkManager.
  };

  nix = {
    gc = {
      dates = "weekly"; # Run age-based GC weekly via systemd.
      persistent = true; # Catch up after boot if the machine missed its scheduled run.
    };
    optimise.dates = [ "daily" ]; # Deduplicate the store daily via systemd timer.
  };

  nixpkgs = {
    config.allowUnfree = true; # Allow unfree packages like Steam and Proton GE.
    overlays = [
      (_final: previous: {
        btop = previous.btop.override {
          rocmSupport = true; # Enable AMD GPU monitoring without globally rebuilding ROCm-capable packages.
        };
      })
    ];
  };

  programs = {
    gamemode.enable = true; # Let games request performance-oriented CPU/GPU tuning.
    gamescope.enableWsi = true; # Install the 64-bit and 32-bit Gamescope Vulkan WSI layers used by the session.
    steam = {
      dedicatedServer.openFirewall = true; # Open firewall ports for Source dedicated servers.
      enable = true; # Install and configure Steam.
      extraCompatPackages = with pkgs; [
        proton-ge-bin # Add Proton GE as an available Steam compatibility tool.
      ];
      extraPackages = [
        steamSessionSelect # Provide the hook Steam invokes for "Switch to Desktop" inside its FHS environment.
      ];
      gamescopeSession = {
        args = [
          "--allow-deferred-backend" # Give logind/DRM a chance to settle when greetd starts Steam very early in boot.
          "--backend"
          "drm" # Force the standalone TTY/KMS backend instead of a nested or headless fallback.
          "--hdr-enabled" # Enable Gamescope HDR support.
          "--prefer-vk-device"
          "1002:73bf" # Prefer the RX 6800 XT instead of Mesa's software Vulkan device during early boot.
          "-r"
          "120" # Target 120 Hz in Gamescope.
        ];
        enable = true; # Add a dedicated Steam-in-Gamescope login session.
        env = {
          AMD_VULKAN_ICD = "RADV"; # Keep AMD hardware rendering ahead of Mesa software fallbacks.
          DXVK_HDR = "1"; # Allow DXVK HDR when the game/Proton path supports it.
          DXVK_LOG_LEVEL = "none"; # Silence DXVK log files unless debugging.
          ENABLE_GAMESCOPE_WSI = "1"; # Use Gamescope's Vulkan WSI layer inside the session.
          VKD3D_DEBUG = "none"; # Silence VKD3D-Proton debug output unless debugging.
        };
        # Match Valve's SteamOS launcher order; `-steamos3` exposes the
        # `steamos-session-select` hook used by "Switch to Desktop".
        steamArgs = [
          "-steamos3"
          "-steampal"
          "-steamdeck"
          "-gamepadui"
          "-pipewire-dmabuf"
        ];
      };
      localNetworkGameTransfers.openFirewall = true; # Open firewall ports for LAN game transfers.
      remotePlay.openFirewall = true; # Open firewall ports for Steam Remote Play.
    };
    zsh.enable = true; # Register zsh as an available login shell.
  };

  services = {
    desktopManager.plasma6.enable = true; # Install Plasma Wayland for desktop mode.
    greetd = {
      enable = true; # Run the minimal login manager for local console sessions.
      settings = {
        default_session = {
          command = tuigreetCommand; # Text fallback if the session router or initial login cannot start.
          user = "greeter"; # Unprivileged greeter account created by the greetd module.
        };
        initial_session = {
          command = steamSessionRouterCommand; # Boot into Gamescope and keep both graphical modes under one login session.
          user = "irish"; # Run both graphical modes as the regular gaming user.
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
  };

  systemd.services.greetd = {
    after = [ "seatd.service" ]; # Start Steam/Gamescope only after seatd can grant KMS/input access.
    wants = [ "seatd.service" ]; # Pull seatd in with greetd even if target ordering changes later.
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
    shell = pkgs.zsh; # Use the Home Manager-managed zsh config for SSH and local shells.
  };
}
