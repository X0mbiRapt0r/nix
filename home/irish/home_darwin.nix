{ config, pkgs, ... }:

let
  nixFlakePath = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix";
  nixFlakeExpr = "builtins.getFlake \"${nixFlakePath}\"";
  mkRepoScriptLink =
    scriptName: config.lib.file.mkOutOfStoreSymlink "${nixFlakePath}/scripts/${scriptName}";
  mikrotikRouterosScript = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "mikrotik-routeros-script";
    publisher = "devMike";
    sha256 = "sha256-RlQbbWZfFfNJ/NTntCOO81IH1s2C0UU9tLHG9n/ttmI=";
    version = "2022.9.2";
  };
  vscodeExtensions = [
    mikrotikRouterosScript
    pkgs.vscode-extensions.jnoortheen.nix-ide
    pkgs.vscode-extensions.mechatroner.rainbow-csv
  ];
  vscodeSettings = {
    "editor.fontFamily" = "JetBrainsMono Nerd Font"; # Editor font.
    "editor.fontLigatures" = true; # Enable coding ligatures.
    "extensions.ignoreRecommendations" = true; # Disable extension recommendations based on workspace files.
    "files.hotExit" = "onExitAndWindowClose"; # Keep dirty editors recoverable even when a folder window is closed.
    "nix.enableLanguageServer" = true; # Let nix-ide use a real Nix LSP instead of prompting for one.
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd"; # Use a store path so GUI-launched editors do not depend on shell PATH.
    "nix.serverSettings" = {
      nixd = {
        formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
        nixpkgs.expr = "import (${nixFlakeExpr}).inputs.nixpkgs { config.allowUnfree = true; }";
        options = {
          home-manager.expr = "(${nixFlakeExpr}).darwinConfigurations.Irish-MBP.options.home-manager.users.type.getSubOptions []";
          nix-darwin.expr = "(${nixFlakeExpr}).darwinConfigurations.Irish-MBP.options";
          nixos.expr = "(${nixFlakeExpr}).nixosConfigurations.XR-PC.options";
        };
      };
    };
    "terminal.integrated.defaultProfile.osx" = "zsh"; # Avoid VS Code auto-picking the Nix zsh path.
    "terminal.integrated.enablePersistentSessions" = true; # Let VS Code restore terminal sessions when it reopens a workspace.
    "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font Mono"; # Integrated terminal font.
    "terminal.integrated.persistentSessionReviveProcess" = "onExitAndWindowClose"; # Revive terminal processes after app quit or window close.
    "terminal.integrated.profiles.osx" = {
      zsh = {
        args = [ "-l" ];
        path = "/bin/zsh";
      };
    };
    "window.openWithoutArgumentsInNewWindow" = "off"; # Reuse the last Code instance instead of creating a new empty window from a Dock/CLI no-argument launch.
    "window.restoreFullscreen" = true; # Preserve fullscreen state when restoring the last working window.
    "window.restoreWindows" = "one"; # Red-button window close clears openedWindows but keeps lastActiveWindow, so restore the last real workspace.
    "workbench.editor.restoreEditors" = true; # Make restored folder windows bring their editor tabs back too.
    "workbench.editor.restoreViewState" = true; # Preserve cursor/scroll state for reopened editors where VS Code can.
    "workbench.startupEditor" = "none"; # Keep restored workspaces from opening a welcome/getting-started editor.
  };
in
{
  home = {
    file = {
      ".local/bin/ngc".source = mkRepoScriptLink "gc"; # Expose Nix garbage collection as `ngc`.
      ".local/bin/nfu".source = mkRepoScriptLink "flake-update"; # Expose flake updates as `nfu`.
      ".local/bin/nix-switch".source = mkRepoScriptLink "switch"; # Expose system switching as `nix-switch`.
    };
    homeDirectory = "/Users/irish"; # macOS home directory.
    packages = with pkgs; [
      nixd # Nix language server used by the nix-ide VS Code extension.
      nixfmt # Formatter used by nixd for Nix files.
    ];
    sessionPath = [ "$HOME/.local/bin" ]; # Put personal helper commands on PATH.
  };

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ]; # Preferred UI language list.
    AppleLocale = "en_ZA"; # Region/locale for dates, numbers, and currency.
  };

  programs.vscode = {
    enable = true; # Manage VS Code settings through Home Manager.
    package = null; # Do not install VS Code with Nix; Homebrew owns the app.
    profiles.default = {
      extensions = vscodeExtensions;
      userSettings = vscodeSettings;
    };
  };
}
