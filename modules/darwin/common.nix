{ config, pkgs, ... }:

{
  # nix-darwin's Nix management
  nix.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  # Your primary user (needed for system.defaults etc)
  system.primaryUser = "irish";

  # Some global packages
  environment.systemPackages = with pkgs; [
    discord
    vscode
  ];

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
      AppleShowAllExtensions = true;
      NSAutomaticWindowAnimationsEnabled = false;
    };
    dock.autohide = true;
    finder.AppleShowAllFiles = true;
  };

  # nix-darwin’s own state version (small integer, not the same as NixOS)
  system.stateVersion = 4;
}
