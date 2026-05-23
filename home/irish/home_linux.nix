{ config, ... }:

let
  nixFlakePath = "${config.home.homeDirectory}/Documents/github.com/X0mbiRapt0r/nix";
  mkRepoScriptLink =
    scriptName: config.lib.file.mkOutOfStoreSymlink "${nixFlakePath}/scripts/${scriptName}";
in
{
  home = {
    file = {
      ".local/bin/ngc".source = mkRepoScriptLink "gc"; # Expose Nix garbage collection as `ngc`.
      ".local/bin/nfu".source = mkRepoScriptLink "flake-update"; # Expose flake updates as `nfu`.
      ".local/bin/nix-switch".source = mkRepoScriptLink "switch"; # Expose system switching as `nix-switch`.
    };
    homeDirectory = "/home/irish"; # Linux home directory.
    sessionPath = [ "$HOME/.local/bin" ]; # Put personal helper commands on PATH.
  };
}
