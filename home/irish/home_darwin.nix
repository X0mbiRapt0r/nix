{ config, ... }:

let
  nixFlakePath = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix";
  mkRepoScriptLink =
    scriptName: config.lib.file.mkOutOfStoreSymlink "${nixFlakePath}/scripts/${scriptName}";
  vscodeSettings = {
    "chat.titleBar.signIn.enabled" = false; # Hide the Copilot/sign-in prompt in the chat title bar.
    # Avoid chat.disableAIFeatures here; it may also block non-Copilot chat extensions we still want to test.
    "editor.fontFamily" = "JetBrainsMono Nerd Font"; # Editor font.
    "editor.fontLigatures" = true; # Enable coding ligatures.
    "extensions.ignoreRecommendations" = true; # Disable extension recommendations based on workspace files.
    "files.hotExit" = "onExitAndWindowClose"; # Keep dirty editors recoverable even when a folder window is closed.
    "github.copilot.chat.backgroundAgent.enabled" = false; # Keep Copilot agent features out of the UI.
    "github.copilot.chat.claudeAgent.enabled" = false; # Keep Copilot agent features out of the UI.
    "github.copilot.chat.cloudAgent.enabled" = false; # Keep Copilot agent features out of the UI.
    "github.copilot.chat.organizationCustomAgents.enabled" = false; # Keep Copilot agent features out of the UI.
    "github.copilot.chat.reviewAgent.enabled" = false; # Keep Copilot agent features out of the UI.
    "github.copilot.enable" = {
      "*" = false;
    }; # Disable Copilot completions if the extension is ever present.
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
    "telemetry.feedback.enabled" = false; # Avoid built-in feedback telemetry prompts.
    "telemetry.telemetryLevel" = "off"; # Disable VS Code/VSCodium telemetry where the build honors it.
    "window.openWithoutArgumentsInNewWindow" = "off"; # Reuse the last Code instance instead of creating a new empty window from a Dock/CLI no-argument launch.
    "window.restoreFullscreen" = true; # Preserve fullscreen state when restoring the last working window.
    "window.restoreWindows" = "folders"; # Restore real folder/workspace windows while skipping empty windows left by macOS close-window behavior.
    "workbench.editor.restoreEditors" = true; # Make restored folder windows bring their editor tabs back too.
    "workbench.editor.restoreViewState" = true; # Preserve cursor/scroll state for reopened editors where VS Code can.
    "workbench.enableExperiments" = false; # Keep Microsoft experiment flags out of the editor surface.
    "workbench.settings.enableNaturalLanguageSearch" = false; # Avoid settings-search calls into online/NL services.
    "workbench.startupEditor" = "none"; # Keep restored workspaces from opening a welcome/getting-started editor.
  };
  vscodeProfile = {
    enableExtensionUpdateCheck = true; # Nix owns managed extension updates.
    enableUpdateCheck = true; # Homebrew/Nix own app updates, not the editor's updater.
    userSettings = vscodeSettings;
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
    sessionPath = [ "$HOME/.local/bin" ]; # Put personal helper commands on PATH.
  };

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ]; # Preferred UI language list.
    AppleLocale = "en_ZA"; # Region/locale for dates, numbers, and currency.
  };

  programs.vscode = {
    enable = true; # Manage VS Code settings through Home Manager.
    mutableExtensionsDir = true; # Let VS Code update/install extensions while HM still seeds the declared set.
    package = null; # Do not install VS Code with Nix; Homebrew owns the app.
    profiles.default = vscodeProfile;
  };
}
