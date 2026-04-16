{ config, pkgs, ... }:

{
  # nix-darwin's Nix management
  nix.enable = true;
  nix.gc = {
    interval = { Weekday = 0; Hour = 0; Minute = 0; };
  };
  # launchd StartCalendarInterval-style schedule
  nix.optimise.interval = [
    { Weekday =0; Hour = 0; Minute = 0; }
  ];

  system.primaryUser = "irish"; # primary user (needed for system.defaults etc)

  environment.systemPackages = with pkgs; [
    freerdp
    go
    mas
    python3
    uv
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;  # or true if you like
      cleanup    = "zap";  # or true to cleanup old stuff on switch
      upgrade    = true;  # or true to upgrade outdated stuff on switch
    };
    casks = [
      "chatgpt"
      "gimp"
      "obsidian"
      "visual-studio-code"
      "whatsapp"
      "winbox"
    ];
    # Mac App Store apps via `mas`
    # NOTE: keys = human-readable app name
    #       values = numeric App Store ID (from `mas list` / `mas search`)
    masApps = {
      "AdGuard Mini"       = 1440147259;
      "Numbers"            = 409203825;
      "Pages"              = 409201541;
    };
  };

  programs.zsh.enable = true; # Make sure zsh is enabled (macOS default shell)

  users.users.irish = {
    home = "/Users/irish";
    shell = pkgs.zsh;
  };

  ids.gids.nixbld = 350;

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = false;
      AppleShowAllFiles = true;
      NSAutomaticWindowAnimationsEnabled = false;
    };
    dock = {
      tilesize = 64;
      magnification = true;
      largesize = 128;
      autohide = true;
    };
    finder  = {
    _FXSortFoldersFirst = true;
    _FXSortFoldersFirstOnDesktop = true;
    AppleShowAllExtensions = false;
    AppleShowAllFiles = false;
    CreateDesktop = true;
    FXDefaultSearchScope = "SCcf";
    FXPreferredViewStyle = "icnv";
    ShowPathbar = true;
    };
  };

  # nix-darwin’s own state version (small integer, not the same as NixOS)
  system.stateVersion = 4;
}
