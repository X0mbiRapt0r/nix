{ config, pkgs, ... }:

{
  # Nix daemon for multi-user
  services.nix-daemon.enable = true;

  # Some global packages
  environment.systemPackages = with pkgs; [
    git
    curl
    htop
  ];

  # Make sure zsh is enabled (macOS default shell)
  programs.zsh.enable = true;

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
