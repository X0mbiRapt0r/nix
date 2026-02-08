{ config, pkgs, ... }:

{
  home.homeDirectory = "/Users/irish";

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ];
    AppleLocale = "en_ZA";
  };

  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontLigatures" = true;
      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font Mono";
      "window.restoreWindows" = "all";
    };
  };

}