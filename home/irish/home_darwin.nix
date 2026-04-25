{ ... }:

{
  home.homeDirectory = "/Users/irish"; # macOS home directory.

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
      "window.restoreWindows" = "all"; # Reopen previous windows on launch.
    };
  };
}
