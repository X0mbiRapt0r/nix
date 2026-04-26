{ config, ... }:

{
  home.homeDirectory = "/Users/irish"; # macOS home directory.
  home.sessionPath = [ "$HOME/.local/bin" ]; # Put personal helper commands on PATH.

  home.file.".local/bin/nix-switch".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix/scripts/switch"; # Expose the repo switch helper as `nix-switch`.
  home.file.".local/bin/nfu".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix/scripts/flake-update"; # Expose the flake update helper as `nfu`.

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ]; # Preferred UI language list.
    AppleLocale = "en_ZA"; # Region/locale for dates, numbers, and currency.
  };

  programs.vscode = {
    enable = true; # Manage VS Code settings through Home Manager.
    package = null; # Do not install VS Code with Nix; Homebrew owns the app.
    pname = "vscode"; # Tell HM which VS Code profile paths to use when package is null.
    profiles.default.userSettings = {
      "editor.fontFamily" = "JetBrainsMono Nerd Font"; # Editor font.
      "editor.fontLigatures" = true; # Enable coding ligatures.
      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font Mono"; # Integrated terminal font.
      "terminal.integrated.defaultProfile.osx" = "zsh"; # Avoid VS Code auto-picking the Nix zsh path.
      "terminal.integrated.profiles.osx" = {
        zsh = {
          path = "/bin/zsh";
          args = [ "-l" ];
        };
      };
      "window.restoreWindows" = "all"; # Reopen previous windows on launch.
    };
  };
}
