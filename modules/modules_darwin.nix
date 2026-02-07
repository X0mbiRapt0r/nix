{ config, pkgs, ... }:

{
  # nix-darwin's Nix management
  nix.enable = true;
  nix.gc = {
    # automatic = true;
    interval = { Weekday = 0; Hour = 0; Minute = 0; };
    # options = "--delete-older-than 30d";
  };
  # launchd StartCalendarInterval-style schedule
  nix.optimise.interval = [
    { Weekday =0; Hour = 0; Minute = 0; }
  ];
  # nix.settings.experimental-features = "nix-command flakes";

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

  environment.etc."sudoers.d/darwin-rebuild-irish" = {
    text = ''
      irish ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    '';
  };

  launchd.user.agents."nix-auto-rebuild" = {

    # nix-darwin will generate a small script with this content
    script = ''
      /bin/zsh -lc "$HOME/.local/bin/nix-auto-rebuild.sh"
    '';

    # These become keys in the launchd plist
    serviceConfig = {
      RunAtLoad = true;  # run once when you log in/unlock
      StartInterval = 900;  # every 900 seconds = 15 minutes
      KeepAlive = false; # don’t restart it; script exits after one run
    };
  };

  # nix-darwin’s own state version (small integer, not the same as NixOS)
  system.stateVersion = 4;
}
