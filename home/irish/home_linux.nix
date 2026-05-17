{ config, ... }:

{
  home.homeDirectory = "/home/irish"; # Linux home directory.
  home.sessionPath = [ "$HOME/.local/bin" ]; # Put personal helper commands on PATH.

  home.file.".local/bin/nix-switch".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/github.com/X0mbiRapt0r/nix/scripts/switch"; # Expose the repo switch helper as `nix-switch`.
  home.file.".local/bin/nfu".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/github.com/X0mbiRapt0r/nix/scripts/flake-update"; # Expose the flake update helper as `nfu`.
  home.file.".local/bin/ngc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/github.com/X0mbiRapt0r/nix/scripts/gc"; # Expose the Nix garbage-collection helper as `ngc`.
}
