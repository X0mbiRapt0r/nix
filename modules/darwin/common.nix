{ config, pkgs, ... }:

{
  # nix-darwin's Nix management
  nix.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  # Your primary user (needed for system.defaults etc)
  system.primaryUser = "irish";

  # Some global packages
  environment.systemPackages = with pkgs; [
    chatgpt
    discord
    go
    mas
    obsidian
    python3
    transmission_4
    vscode
    winbox4
    uv
  ];

  homebrew = {
    enable = true;

    # Don’t auto-upgrade everything on every rebuild unless you want that
    onActivation = {
      autoUpdate = true;  # or true if you like
      upgrade    = true;  # or true to upgrade outdated stuff on switch
    };

    # Mac App Store apps via `mas`
    #
    # NOTE: keys = human-readable app name
    #       values = numeric App Store ID (from `mas list` / `mas search`)
    masApps = {
      "AdGuard for Safari" = 1440147259;
      "Numbers"            = 409203825;
      "Pages"              = 409201541;
      "WhatsApp"           = 310633997;
      # add more as you wish
    };
  };

  # Make sure zsh is enabled (macOS default shell)
  programs.zsh.enable = true;

  users.users.irish = {
    home = "/Users/irish";
    shell = pkgs.zsh;
  };

  ids.gids.nixbld = 350;

  # A couple of macOS defaults (tweak later)
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

  # security.sudo.enable = true;

  # security.sudo.extraConfig = ''
  #   irish ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  # '';

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
      KeepAlive = false; # don’t restart it; script exits after one run
    };
  };

  # nix-darwin’s own state version (small integer, not the same as NixOS)
  system.stateVersion = 4;
}
