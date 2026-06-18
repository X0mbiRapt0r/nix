{ config, ... }:

let
  nixFlakePath = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix";
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
    homeDirectory = "/Users/irish"; # macOS home directory.
    sessionPath = [ "$HOME/.local/bin" ]; # Put personal helper commands on PATH.
  };

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ]; # Preferred UI language list.
    AppleLocale = "en_ZA"; # Region/locale for dates, numbers, and currency.
  };
}
