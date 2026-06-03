{
  config,
  lib,
  pkgs,
  ...
}:

let
  primaryUser = "irish";
in
{
  environment.systemPackages = with pkgs; [
    freerdp # RDP client.
    go # Go toolchain.
    mas # Mac App Store CLI, useful for discovering/installing App Store IDs.
    python3 # Python runtime.
    uv # Fast Python package/project manager.
  ];

  homebrew = {
    casks = [
      "chatgpt" # ChatGPT desktop app.
      "codex-app" # Codex desktop app.
      "gimp" # Image editor.
      "obsidian" # Notes/knowledge base.
      "visual-studio-code" # VS Code app; settings are managed by Home Manager.
      "whatsapp" # Messaging app.
      "winbox" # MikroTik router management app.
      # "wireguard" # WireGuard VPN client.
    ];
    enable = true; # Let nix-darwin produce and apply a Brewfile.
    onActivation = {
      autoUpdate = true; # Run `brew update` during activation.
      cleanup = "zap"; # Remove casks/formulas no longer declared here, including zap cleanup.
      extraFlags = [
        "--force-cleanup" # Homebrew Bundle now requires explicit confirmation for `--cleanup` during install.
      ];
      upgrade = true; # Upgrade outdated Homebrew packages during activation.
    };
  };

  ids.gids.nixbld = 350; # Stable nixbld group ID used by nix-darwin on macOS.

  nix = {
    enable = true; # Let nix-darwin manage the Nix daemon and nix.conf.
    gc.interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    }; # Run GC weekly at Sunday 00:00 via launchd.
    optimise.interval = [
      {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      } # Run store optimisation weekly at Sunday 00:00.
    ];
  };

  programs.zsh.enable = true; # Register zsh as an available shell.

  system = {
    activationScripts.postActivation.text = lib.mkAfter ''
      if [ -x "${config.homebrew.prefix}/bin/brew" ]; then
        echo >&2 "Cleaning Homebrew cache..."

        # `homebrew.onActivation.cleanup = "zap"` removes packages/casks that no
        # longer belong to the generated Brewfile. This separate cleanup trims the
        # download cache that Homebrew keeps around for future reinstalls.
        if ! PATH="${config.homebrew.prefix}/bin:$PATH" \
          sudo --preserve-env=PATH --user=${primaryUser} --set-home \
            brew cleanup --prune=all; then
          echo >&2 "warning: Homebrew cache cleanup failed; continuing activation."
        fi
      fi
    '';

    defaults = {
      CustomUserPreferences = {
        "com.apple.dock" = {
          "show-recent-count" = 5;
        };
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = false; # Keep filename extensions hidden globally unless an app overrides it.
        NSAutomaticWindowAnimationsEnabled = false; # Reduce window animation delays.
      };
      dock = {
        autohide = true; # Hide the Dock until the pointer reaches the screen edge.
        largesize = 128; # Maximum Dock magnification size.
        magnification = true; # Enlarge icons under the pointer.
        show-recents = true; # Show recently used apps in the Dock.
        tilesize = 64; # Default Dock icon size.
      };
      finder = {
        AppleShowAllExtensions = false; # Keep filename extensions hidden in Finder.
        AppleShowAllFiles = true; # Show hidden dotfiles in Finder.
        CreateDesktop = true; # Show Desktop icons.
        FXDefaultSearchScope = "SCcf"; # Search the current folder by default.
        FXPreferredViewStyle = "icnv"; # Use icon view by default.
        ShowPathbar = true; # Show the Finder path bar.
        _FXSortFoldersFirst = true; # Show folders before files in Finder windows.
        _FXSortFoldersFirstOnDesktop = true; # Show folders before files on the Desktop.
      };
    };

    primaryUser = primaryUser; # User whose defaults are managed by system.defaults.
    stateVersion = 4; # nix-darwin state version; do not bump casually.
  };

  users.users.${primaryUser} = {
    home = "/Users/${primaryUser}"; # macOS home directory.
    shell = "/bin/zsh"; # Use macOS zsh; Home Manager still owns the interactive config.
  };
}
