{ pkgs, ... }:

let
  primaryUser = "irish";
in
{
  environment.systemPackages = with pkgs; [
    go
    uv
  ];

  homebrew = {
    brews = [
      "mole"
    ];
    casks = [
      "gimp"
      #"obsidian"
      "radix"
      "visual-studio-code" # VS Code app; preferences and extensions use its built-in Settings Sync.
      "vlc"
      "whatsapp"
      "winbox"
    ];
    enable = true; # Let nix-darwin produce and apply a Brewfile.
    onActivation = {
      autoUpdate = true; # Refresh Homebrew metadata during activation.
      cleanup = "zap"; # Remove undeclared packages and associated cask files during activation.
      upgrade = true; # Upgrade declared packages using the currently available Homebrew metadata.
    };
  };

  # Keep the existing group ID despite stateVersion 4's legacy default of 30000.
  ids.gids.nixbld = 350;

  nix = {
    gc.interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    }; # Run age-based GC weekly at Sunday 00:00 via launchd; missed sleep events run after wake.
    optimise.interval = [
      {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      } # Run store optimisation weekly at Sunday 00:00.
    ];
  };

  programs.zsh.enable = true; # Register zsh as an available shell.

  system = {
    defaults = {
      CustomUserPreferences = {
        "com.apple.dock" = {
          "show-recent-count" = 4; # Limit the Dock's recent-app section to four items.
        };
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = false; # Keep filename extensions hidden globally unless an app overrides it.
        NSAutomaticWindowAnimationsEnabled = false; # Reduce window animation delays.
      };
      dock = {
        autohide = true; # Hide the Dock until the pointer reaches the screen edge.
        largesize = 128; # Maximum Dock magnification size.
        magnification = true; # Enlarge icons under the pointer.
        show-recents = true; # Show recently used apps in the Dock.
        tilesize = 64; # Default Dock icon size.
      };
      finder = {
        AppleShowAllExtensions = false; # Keep filename extensions hidden in Finder.
        AppleShowAllFiles = true; # Show hidden dotfiles in Finder.
        CreateDesktop = true; # Show Desktop icons.
        FXDefaultSearchScope = "SCcf"; # Search the current folder by default.
        FXPreferredViewStyle = "icnv"; # Use icon view by default.
        ShowPathbar = true; # Show the Finder path bar.
        _FXSortFoldersFirst = true; # Show folders before files in Finder windows.
        _FXSortFoldersFirstOnDesktop = true; # Show folders before files on the Desktop.
      };
    };

    primaryUser = primaryUser; # User whose defaults are managed by system.defaults.
    stateVersion = 4; # nix-darwin state version; do not bump casually.
  };

  users.users.${primaryUser} = {
    home = "/Users/${primaryUser}"; # macOS home directory.
    shell = "/bin/zsh"; # Use macOS zsh; Home Manager still owns the interactive config.
  };
}
