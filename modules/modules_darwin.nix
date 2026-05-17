{ config, pkgs, ... }:

let
  primaryUser = "irish";
  autoUpdateRepo = "/Users/${primaryUser}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix";
  autoUpdatePath = builtins.concatStringsSep ":" [
    "${config.nix.package}/bin"
    "${config.system.build.darwin-rebuild}/bin"
    "${pkgs.bash}/bin"
    "${pkgs.coreutils}/bin"
    "${pkgs.git}/bin"
    "${pkgs.openssh}/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
in
{
  nix.enable = true; # Let nix-darwin manage the Nix daemon and nix.conf.
  nix.gc = {
    interval = { Weekday = 0; Hour = 0; Minute = 0; }; # Run GC weekly at Sunday 00:00 via launchd.
  };
  nix.optimise.interval = [
    { Weekday = 0; Hour = 0; Minute = 0; } # Run store optimisation weekly at Sunday 00:00.
  ];

  system.primaryUser = primaryUser; # User whose defaults are managed by system.defaults.

  environment.systemPackages = with pkgs; [
    freerdp # RDP client.
    go # Go toolchain.
    mas # Mac App Store CLI, useful for discovering/installing App Store IDs.
    python3 # Python runtime.
    uv # Fast Python package/project manager.
  ];

  homebrew = {
    enable = true; # Let nix-darwin produce and apply a Brewfile.
    onActivation = {
      autoUpdate = true; # Run `brew update` during activation.
      cleanup = "zap"; # Remove casks/formulas no longer declared here, including zap cleanup.
      upgrade = true; # Upgrade outdated Homebrew packages during activation.
    };
    casks = [
      "chatgpt" # ChatGPT desktop app.
      "codex-app" # Codex desktop app.
      "obsidian" # Notes/knowledge base.
      "visual-studio-code" # VS Code app; settings are managed by Home Manager.
      "whatsapp" # Messaging app.
      "winbox" # MikroTik router management app.
      # "wireguard" # WireGuard VPN client.
    ];
  };

  programs.zsh.enable = true; # Register zsh as an available shell.

  launchd.daemons.nix-auto-update = {
    script = ''
      set -euo pipefail

      export PATH="${autoUpdatePath}"

      # Keep the Git checkout owned by Irish even though activation itself
      # needs to run as root.
      /usr/bin/sudo -H -u ${primaryUser} /usr/bin/env PATH="$PATH" git -C "${autoUpdateRepo}" pull --ff-only
      /usr/bin/sudo -H -u ${primaryUser} /usr/bin/env PATH="$PATH" "${pkgs.bash}/bin/bash" "${autoUpdateRepo}/scripts/flake-update" --repo "${autoUpdateRepo}"

      # Reuse the same switch helper as `nrs`. The pull already happened above,
      # so do not repeat it here.
      "${pkgs.bash}/bin/bash" "${autoUpdateRepo}/scripts/switch" --repo "${autoUpdateRepo}" --no-pull
    '';
    serviceConfig = {
      RunAtLoad = false; # Do not update immediately after every nix-darwin activation.
      StartCalendarInterval = { Hour = 2; Minute = 0; }; # Daily 02:00; launchd coalesces missed runs after wake.
      StandardErrorPath = "/var/log/nix-auto-update.log";
      StandardOutPath = "/var/log/nix-auto-update.log";
      WorkingDirectory = autoUpdateRepo;
    };
  };

  users.users.${primaryUser} = {
    home = "/Users/${primaryUser}"; # macOS home directory.
    shell = "/bin/zsh"; # Use macOS zsh; Home Manager still owns the interactive config.
  };

  ids.gids.nixbld = 350; # Stable nixbld group ID used by nix-darwin on macOS.

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = false; # Keep filename extensions hidden globally unless an app overrides it.
      NSAutomaticWindowAnimationsEnabled = false; # Reduce window animation delays.
    };
    CustomUserPreferences = {
      "com.apple.dock" = {
        "show-recent-count" = 5;
      };
    };
    dock = {
      tilesize = 64; # Default Dock icon size.
      magnification = true; # Enlarge icons under the pointer.
      largesize = 128; # Maximum Dock magnification size.
      autohide = true; # Hide the Dock until the pointer reaches the screen edge.
      show-recents = true; # Show recently used apps in the Dock.
    };
    finder = {
      _FXSortFoldersFirst = true; # Show folders before files in Finder windows.
      _FXSortFoldersFirstOnDesktop = true; # Show folders before files on the Desktop.
      AppleShowAllExtensions = false; # Keep filename extensions hidden in Finder.
      AppleShowAllFiles = true; # Show hidden dotfiles in Finder.
      CreateDesktop = true; # Show Desktop icons.
      FXDefaultSearchScope = "SCcf"; # Search the current folder by default.
      FXPreferredViewStyle = "icnv"; # Use icon view by default.
      ShowPathbar = true; # Show the Finder path bar.
    };
  };

  system.stateVersion = 4; # nix-darwin state version; do not bump casually.
}
