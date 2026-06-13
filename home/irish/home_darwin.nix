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
  nixdSettings = {
    formatting.command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
    nixpkgs.expr = "import (${nixFlakeExpr}).inputs.nixpkgs { config.allowUnfree = true; }";
    options = {
      home-manager.expr = "(${nixFlakeExpr}).darwinConfigurations.Irish-MBP.options.home-manager.users.type.getSubOptions []";
      nix-darwin.expr = "(${nixFlakeExpr}).darwinConfigurations.Irish-MBP.options";
      nixos.expr = "(${nixFlakeExpr}).nixosConfigurations.XR-PC.options";
    };
  };
  codeFamilyExtensions = [
    mikrotikRouterosScript
    pkgs.vscode-extensions.jnoortheen.nix-ide
    pkgs.vscode-extensions.mechatroner.rainbow-csv
  ];
  codeFamilySettings = {
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
    "nix.enableLanguageServer" = true; # Let nix-ide use a real Nix LSP instead of prompting for one.
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd"; # Use a store path so GUI-launched editors do not depend on shell PATH.
    "nix.serverSettings" = {
      nixd = nixdSettings;
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
  codeFamilyProfile = {
    enableExtensionUpdateCheck = false; # Nix owns managed extension updates.
    enableUpdateCheck = false; # Homebrew/Nix own app updates, not the editor's updater.
    extensions = codeFamilyExtensions;
    userSettings = codeFamilySettings;
  };
  zedExtensions = [
    "csv"
    "nix"
    "rainbow-csv"
  ];
  zedSettings = {
    auto_update = false; # Let Nix update Zed rather than Zed updating itself.
    base_keymap = "VSCode"; # Keep common shortcut muscle memory while testing editors side-by-side.
    buffer_font_family = "JetBrainsMono Nerd Font"; # Match the Code-family editor font.
    # Keep Zed's agent surface available for testing; only predictive edits are disabled here.
    edit_predictions.provider = "none"; # Leave predictive AI edits off unless explicitly enabled later.
    format_on_save = "off"; # Match the current VS Code setup, which does not force format-on-save.
    languages.Nix = {
      formatter.external = {
        arguments = [ ];
        command = "${pkgs.nixfmt}/bin/nixfmt";
      };
      language_servers = [
        "nixd"
        "!nil"
      ];
    };
    load_direnv = "shell_hook"; # Match shell-hook based project environments when Zed opens a workspace.
    lsp.nixd = {
      binary.path = "${pkgs.nixd}/bin/nixd";
      settings = nixdSettings;
    };
    restore_on_startup = "last_workspace"; # Closest Zed match for restoring folder/workspace windows.
    telemetry = {
      diagnostics = false;
      metrics = false;
    };
    terminal = {
      font_family = "JetBrainsMono Nerd Font Mono";
      shell = {
        args = [ "-l" ];
        program = "/bin/zsh";
      };
    };
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
    mutableExtensionsDir = false; # Keep managed extensions reproducible instead of letting the app mutate them.
    package = null; # Do not install VS Code with Nix; Homebrew owns the app.
    profiles.default = codeFamilyProfile;
  };

  programs.vscodium = {
    enable = true; # Install/manage VSCodium alongside VS Code for a non-Microsoft build.
    mutableExtensionsDir = false; # Use the same immutable extension model as VS Code.
    profiles.default = codeFamilyProfile;
  };

  programs.zed-editor = {
    enable = true; # Install/manage Zed as another editor candidate.
    extensions = zedExtensions;
    extraPackages = with pkgs; [
      nixd # Put nixd on PATH for Zed's wrapped launcher.
      nixfmt # Put nixfmt on PATH for Zed's wrapped launcher.
    ];
    mutableUserDebug = false; # Keep Zed config files fully Home Manager managed.
    mutableUserKeymaps = false; # Keep Zed config files fully Home Manager managed.
    mutableUserSettings = false; # Keep Zed config files fully Home Manager managed.
    mutableUserTasks = false; # Keep Zed config files fully Home Manager managed.
    userSettings = zedSettings;
  };
}
