{ ... }:

{
  home = {
    file = {
      ".local/bin/ngc".source = ../../scripts/gc; # Expose Nix garbage collection as `ngc`.
      ".local/bin/nfu".source = ../../scripts/flake-update; # Expose flake updates as `nfu`.
      ".local/bin/nix-switch".source = ../../scripts/switch; # Expose system switching as `nix-switch`.
    };
    sessionPath = [
      "$HOME/.local/bin" # Prefer personal helper commands over language-specific binaries.
      "$HOME/go/bin"
    ];
    stateVersion = "24.05"; # Original Home Manager compatibility baseline; do not follow input updates.
    username = "irish"; # Account name managed by Home Manager.
  };

  programs = {
    git = {
      enable = true; # Generate ~/.gitconfig.
      ignores = [
        # Keep OS-generated noise global; project and tool artefacts belong in each repo.

        # Linux desktop and filesystem metadata.
        ".directory"
        ".fuse_hidden*"
        ".nfs*"
        ".Trash-*"

        # macOS desktop and filesystem metadata.
        "._*"
        ".AppleDouble"
        ".DS_Store"
        ".localized"
        ".LSOverride"
        ".Spotlight-V100"
        ".Trashes"
        "__MACOSX/"

        # Windows desktop and filesystem metadata.
        "$RECYCLE.BIN/"
        "[Dd]esktop.ini"
        "ehthumbs.db"
        "ehthumbs_vista.db"
        "Thumbs.db"
        "Thumbs.db:encryptable"
      ];
      settings = {
        init.defaultBranch = "main"; # New repos start on main.
        pull.rebase = true; # Rebase local commits when pulling.
        user = {
          email = "11319449+X0mbiRapt0r@users.noreply.github.com"; # GitHub noreply commit email.
          name = "X0mbiRapt0r"; # Commit author name.
        };
      };
    };

    zsh = {
      autosuggestion.enable = true; # Suggest commands from history as you type.
      enable = true; # Manage ~/.zshrc with Home Manager.
      enableCompletion = true; # Enable shell completions.

      initContent = ''
        PROMPT='%n@%m:%1~ > '
      '';

      shellAliases = {
        gacp = "git add . && git commit -m 'quick update' && git push origin main"; # Quick personal commit/push helper.
        gs = "git status"; # Short git status.
        ll = "lsd -lah"; # Long listing with hidden files.
        ls = "lsd"; # Use lsd for basic listings.
        lt = "lsd --tree"; # Tree-style listing.
        nrs = "command nix-switch"; # Build and activate this host's flake configuration.
      };

      syntaxHighlighting.enable = true; # Highlight commands while typing.
    };
  };
}
