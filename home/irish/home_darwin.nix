{ config, pkgs, ... }:

let
  nixFlakePath = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix";
  mikrotikRouterosScript = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "mikrotik-routeros-script";
    publisher = "devMike";
    version = "2022.9.2";
    sha256 = "sha256-RlQbbWZfFfNJ/NTntCOO81IH1s2C0UU9tLHG9n/ttmI=";
  };
  vscodeExtensions = [
    mikrotikRouterosScript
    pkgs.vscode-extensions.jnoortheen.nix-ide
    pkgs.vscode-extensions.mechatroner.rainbow-csv
  ];
  vscodeSettings = {
    "editor.fontFamily" = "JetBrainsMono Nerd Font"; # Editor font.
    "editor.fontLigatures" = true; # Enable coding ligatures.
    "nix.enableLanguageServer" = true; # Let nix-ide use a real Nix LSP instead of prompting for one.
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd"; # Use a store path so GUI-launched editors do not depend on shell PATH.
    "nix.serverSettings" = {
      nixd = {
        formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
        nixpkgs.expr = "import (builtins.getFlake \"${nixFlakePath}\").inputs.nixpkgs { config.allowUnfree = true; }";
        options = {
          home-manager.expr = "(builtins.getFlake \"${nixFlakePath}\").darwinConfigurations.Irish-MBP.options.home-manager.users.type.getSubOptions []";
          nix-darwin.expr = "(builtins.getFlake \"${nixFlakePath}\").darwinConfigurations.Irish-MBP.options";
          nixos.expr = "(builtins.getFlake \"${nixFlakePath}\").nixosConfigurations.XR-PC.options";
        };
      };
    };
    "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font Mono"; # Integrated terminal font.
    "terminal.integrated.defaultProfile.osx" = "zsh"; # Avoid VS Code auto-picking the Nix zsh path.
    "terminal.integrated.profiles.osx" = {
      zsh = {
        path = "/bin/zsh";
        args = [ "-l" ];
      };
    };
    "files.hotExit" = "onExitAndWindowClose"; # Keep dirty editors recoverable even when a folder window is closed.
    "terminal.integrated.enablePersistentSessions" = true; # Let VS Code restore terminal sessions when it reopens a workspace.
    "terminal.integrated.persistentSessionReviveProcess" = "onExitAndWindowClose"; # Revive terminal processes after app quit or window close.
    "window.restoreWindows" = "folders"; # Reopen folder workspaces and ignore empty windows that can strand us on a blank launch.
    "workbench.editor.restoreEditors" = true; # Make restored folder windows bring their editor tabs back too.
    "workbench.editor.restoreViewState" = true; # Preserve cursor/scroll state for reopened editors where VS Code can.
    "workbench.startupEditor" = "none"; # Keep restored workspaces from opening a welcome/getting-started editor.
    "extensions.ignoreRecommendations" = true; # Disable extension recommendations based on workspace files.
  };
in
{
  home.homeDirectory = "/Users/irish"; # macOS home directory.
  home.packages = with pkgs; [
    nixd # Nix language server used by the nix-ide VS Code extension.
    nixfmt # Formatter used by nixd for Nix files.
  ];
  home.sessionPath = [ "$HOME/.local/bin" ]; # Put personal helper commands on PATH.

  home.file.".local/bin/nix-switch".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix/scripts/switch"; # Expose the repo switch helper as `nix-switch`.
  home.file.".local/bin/nfu".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix/scripts/flake-update"; # Expose the flake update helper as `nfu`.
  home.file.".local/bin/ngc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix/scripts/gc"; # Expose the Nix garbage-collection helper as `ngc`.

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ]; # Preferred UI language list.
    AppleLocale = "en_ZA"; # Region/locale for dates, numbers, and currency.
  };

  programs.vscode = {
    enable = true; # Manage VS Code settings through Home Manager.
    package = null; # Do not install VS Code with Nix; Homebrew owns the app.
    profiles.default = {
      userSettings = vscodeSettings;
      extensions = vscodeExtensions;
    };
  };
}
